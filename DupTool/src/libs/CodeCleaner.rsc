module libs::CodeCleaner

import IO;
import String;
import List;
import Set;
import Map;
import Relation;
import lang::java::m3::Core;
import lang::java::m3::Registry;

//return total volume and every compilation unit with their lines of code (needed for duplication scan)
public tuple[int, map[loc, list[str]]] GetModelVolume(M3 model, map[str, set[loc]] docs)
{
	map[loc,list[str]] cuSizes = ();
	set[loc] cmpUnits = { d | d <- domain(model@declarations), isCompilationUnit(d)};
			
	int volume = 0;
	int count = 0;
	int total = size(cmpUnits);
	
	for(cUnit <- cmpUnits)
	{
		loc cLoc = resolveJava(cUnit);
		list[str] lines = TrimWhiteLines(FilterDocumentation(cLoc, docs[cLoc.uri]));

		//store filtered lines for later use (duplication)
		cuSizes[cUnit] = lines;
		
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
private list[str] FilterDocumentation(loc source, set[loc] docs)
{
	list[str] fileLines = readFileLines(source);
		
	for(d <- docs)
	{		
		int sIdx = d.begin.line - source.begin.line;
		int eIdx = sIdx + (d.end.line - d.begin.line);		
		
		if(eIdx == sIdx)
		{
			str line = fileLines[sIdx];
						
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
				
			fileLines[sIdx] =  ReplaceWithWhiteSpace(line, sCol, eCol);
		}		
		else
		{
			//first docline
			str line = fileLines[sIdx];		
			int sCol = d.begin.column;
			
			//get correct startindex if source.line equals doc.line
			if(sIdx == 0)
				sCol = d.begin.column - source.begin.column;
				
			fileLines[sIdx] = ReplaceWithWhiteSpace(line, sCol, size(line));
					
			//middle doclines	
			for(idx <- [sIdx+1..eIdx])
				fileLines[idx] = "";
			
			//last docline
			line = fileLines[eIdx];	
			sCol = 0;
			int eCol = d.end.column;
			if(eCol > size(line))
				eCol = d.end.column - d.begin.column;
			
			fileLines[eIdx] = ReplaceWithWhiteSpace(line, sCol, eCol);			
		}
	}	
		
	return fileLines;						
}

private list[str] TrimWhiteLines(list[str] lines) = [line | line <- lines, trim(line) != ""];

private str ReplaceWithWhiteSpace(str line, int sCol, int eCol) = substring(line, 0, sCol) + substring(line, eCol);