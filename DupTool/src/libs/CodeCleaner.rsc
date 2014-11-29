module libs::CodeCleaner

import IO;
import String;
import List;
import Set;
import Map;
import Relation;

import lang::java::m3::Core;
import lang::java::m3::Registry;
import libs::LocationHelpers;

//return total volume and every compilation unit with their lines of code (needed for duplication scan)
public tuple[int, map[loc, list[lline]]] GetModelVolume(M3 model, map[str, set[loc]] docs)
{
	map[loc,list[lline]] cuSizes = ();
	set[loc] cmpUnits = { d | d <- domain(model@declarations), isCompilationUnit(d)};
			
	int volume = 0;
	int count = 0;
	int total = size(cmpUnits);
	
	for(cUnit <- cmpUnits)
	{
		loc cLoc = resolveJava(cUnit);
		
			
		list[lline] lines = TrimWhiteLines(FilterDocumentation(cLoc, docs[cLoc.uri]));

		//store filtered lines for later use (duplication)
		cuSizes[cLoc] = lines;
		
		//compute volume (so-far) here
		volume += size(lines);
		
		count += 1;
		if(count % 5 == 0)
			println("--\> compilation unit <count> of <total> - LOC so far: <volume>");
	}

	println("--\> Processed <count> compilation units in total");
	return <volume, cuSizes>;
}

//check if location exists within range of another location 
private bool IsInRange(loc range, loc target)
{
	//target before range
	if(range.begin.line > target.end.line)
		return false;

	//target after range
	if(target.begin.line > range.end.line)
		return false;
	
	return true;
}

//return list[str] with contents in which documentation is replaced with whitespace
private list[lline] FilterDocumentation(loc source, set[loc] docs)
{
	list[lline] lines = GetLineDescriptors(readFileLines(source));
		
	for(d <- docs)
	{		
		int sIdx = d.begin.line - source.begin.line;
		int eIdx = sIdx + (d.end.line - d.begin.line);		
		
		if(eIdx == sIdx)
		{
			str line = lines[sIdx][0];
						
			int sCol = d.begin.column;
			int eCol = d.end.column;		
			
			//get correct startindex
			if(sIdx == 0)
			{
				sCol = d.begin.column - source.begin.column;
				eCol = d.end.column - sCol;
			}
				
			if(eCol > size(line))
				eCol = d.end.column - d.begin.column;
				
			lines[sIdx] = <ReplaceWithWhiteSpace(line, sCol, eCol), lines[sIdx][1], lines[sIdx][2]>;
		}		
		else
		{
			//first docline
			str line = lines[sIdx][0];		
			int sCol = d.begin.column;
			
			//get correct startindex if source.line equals doc.line
			if(sIdx == 0)
				sCol = d.begin.column - source.begin.column;
				
			lines[sIdx] = <ReplaceWithWhiteSpace(line, sCol, size(line)), lines[sIdx][1], lines[sIdx][2]>;
					
			//middle doclines	
			for(idx <- [sIdx+1..eIdx])
				lines[idx] = <"",lines[idx][1],lines[idx][2]>;
			
			//last docline
			line = lines[eIdx][0];	
			sCol = 0;
			int eCol = d.end.column;
			if(eCol > size(line))
				eCol = d.end.column - d.begin.column;
			
			lines[eIdx] = <ReplaceWithWhiteSpace(line, sCol, eCol), lines[eIdx][1], lines[eIdx][2]>;		
		}
	}	
		
	return lines;						
}

private list[lline] TrimWhiteLines(list[lline] lines) = [line | line <- lines, trim(line[0]) != ""];

private str ReplaceWithWhiteSpace(str line, int sCol, int eCol) = substring(line, 0, sCol) + substring(line, eCol);