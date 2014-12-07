module modules::CodeCleaner

import IO;
import String;
import List;
import Set;
import Map;
import Relation;

import lang::java::m3::Core;
import helpers::Location;
import helpers::String;

//return total volume and every compilation unit with their lines of code (needed for duplication scan)
public tuple[int, map[loc, list[lline]]] GetModelVolume(M3 model, map[str, set[loc]] docs)
{
	map[loc,list[lline]] cSizes = ();
	set[loc] cUnits = { d | d <- domain(model@declarations), isCompilationUnit(d)};
			
	int volume = 0;
	int count = 0;
	int total = size(cUnits);
	
	for(cUnit <- cUnits)
	{
		loc cLoc;
		if (<cUnit, src> <- model@declarations)
    		cLoc = src;
		
		set[loc] cDocs = {};
		if(cLoc.uri in docs)	
			cDocs = docs[cLoc.uri];
			
		list[lline] lines = [line | line <- FilterDocumentation(cLoc, cDocs), trim(line[0]) != ""];

		//store filtered lines for later use (duplication)
		cSizes[cLoc] = lines;
		
		//compute volume (so-far) here
		volume += size(lines);
		
		count += 1;
		if(count % 5 == 0)
			println("--\> compilation unit <count> of <total> - LOC so far: <volume>");
	}

	println("--\> Processed <count> compilation units in total");
	return <volume, cSizes>;
}

//return list[str] with contents in which documentation is replaced with whitespace
private list[lline] FilterDocumentation(loc source, set[loc] docs)
{
	list[lline] lines = GetLineDescriptors(readFileLines(source));
	
	for(doc <- docs)
	{		
		int sIdx = lineBgn(doc) - lineBgn(source);
		int eIdx = sIdx + (lineEnd(doc) - lineBgn(doc));		
		
		if(eIdx == sIdx)
		{
			str line = lines[sIdx][0];
						
			int sCol = colBgn(doc);
			int eCol = colEnd(doc);		
			
			//get correct startindex
			if(sIdx == 0)
			{
				sCol = colBgn(doc) - colBgn(source);
				eCol = colEnd(doc) - sCol;
			}
				
			if(eCol > size(line))
				eCol = colEnd(doc) - colBgn(doc);
				
			lines[sIdx] = <FilterStrSection(line, sCol, eCol), lines[sIdx][1], lines[sIdx][2]>;
		}		
		else
		{
			//first docline
			str line = lines[sIdx][0];		
			int sCol = colBgn(doc);
			
			//get correct startindex if source.line equals doc.line
			if(sIdx == 0)
				sCol = colBgn(doc) - colBgn(source);
				
			lines[sIdx] = <FilterStrSection(line, sCol, size(line)), lines[sIdx][1], lines[sIdx][2]>;
					
			//middle doclines	
			for(idx <- [sIdx+1..eIdx])
				lines[idx] = <"",lines[idx][1],lines[idx][2]>;
			
			//last docline
			line = lines[eIdx][0];	
			sCol = 0;
			int eCol = colEnd(doc);
			if(eCol > size(line))
				eCol = colEnd(doc) - colBgn(doc);
			
			lines[eIdx] = <FilterStrSection(line, sCol, eCol), lines[eIdx][1], lines[eIdx][2]>;		
		}
	}	
		
	return lines;						
}