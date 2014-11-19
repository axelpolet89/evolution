module computations::LinesOfCode

import IO;
import String;
import List;
import Set;
import Map;
import Relation;
import lang::java::m3::Core;
import lang::java::m3::Registry;

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
private list[str] ParseSourceNoDocs(loc source, set[loc] docs)
{
	list[str] fileLines = readFileLines(source);
	list[int] lIndices = [source.begin.line..source.end.line + 1];
	
	for(d <- docs)
	{	
		//indices on which documentation starts/ends in 'source' array 
		int sIdx = indexOf(lIndices, d.begin.line);
		int eIdx = indexOf(lIndices, d.end.line);
		
		for(lineIdx <- [sIdx..eIdx + 1])
		{
			str replacement = "";
		
			//perform specific replace of documentation with whitespace	
			if(lineIdx == 0 || lineIdx == sIdx)
			{
				str line = fileLines[lineIdx];
				int sCol = 0;
				int eCol = size(line);
			
				list[int] cIndices = [sCol..eCol + 1];
			
				//documentation at begin of source, begin on first char of source
				if(lineIdx == 0)
					sCol = d.begin.column - source.begin.column;
				else //first line of documentation; get correct startindex
					sCol = indexOf(cIndices, d.begin.column);
				
				//last line of documentation; get correct endindex
				if(lineIdx == eIdx)
				{
					eCol = indexOf(cIndices, d.end.column);
					if(eCol == -1) //fix: leading tabs/spaces are not accounted for by readFileLines
						eCol = indexOf(cIndices, d.end.column - d.begin.column);
				}
	
				replacement =  substring(line, 0, sCol) + substring(line, eCol);
			}
			
			fileLines[lineIdx] = replacement;
		}
	}	
		
	return fileLines;						
}


//return total volume and every compilation unit with their lines of code (needed for duplication scan)
public tuple[int, map[loc, list[str]]] GetModelVolume(M3 model, map[str, map[bool, set[loc]]] docs)
{
	map[loc,list[str]] cuSizes = ();
	set[loc] cmpUnits = { d | d <- domain(model@declarations), isCompilationUnit(d)};
			
	int volume = 0;
	int count = 0;
	int total = size(cmpUnits);
	
	for(cUnit <- cmpUnits)
	{
		loc cLoc = resolveJava(cUnit);
		list[str] lines = ParseSourceNoDocs(cLoc, docs[cLoc.uri][false]);
		
		//filter javadoc (faster)
		int totalJavaDoc = 0;
		for(d <- {doc | doc <- docs[cLoc.uri][true]})
			for(idx <- [d.begin.line-1..d.end.line])
				lines[idx] = "";

		cuSizes[cUnit] = [line | line <- lines, trim(line) != ""];
		volume += size(cuSizes[cUnit]);
		
		count += 1;
		if(count % 5 == 0)
			println("--\> compilation unit <count> of <total> - LOC so far: <volume>");
	}

	println("--\> Processed <count> compilation units in total");
	return <volume, cuSizes>;
}


//return map of method with it's LOC
public map[loc, int] GetModelUnitSizes(M3 model, map[str, map[bool, set[loc]]] docs)
{	
	map[loc, int] result = ();
	count = 0;
		
	//loop methods
	for(m <- methods(model))
	{		
		loc mLoc = resolveJava(m);
		int unitLOC = size(ParseSourceNoDocs(mLoc, {doc | doc <- docs[mLoc.uri][false], IsInRange(mLoc, doc)}));
				
		//substract javadoc (faster)
		int totalJavaDoc = 0;
		for(d <- {doc | doc <- docs[mLoc.uri][true], IsInRange(mLoc, doc)})
			totalJavaDoc += (d.end.line - d.begin.line + 1);
		
		result[m] = unitLOC - totalJavaDoc;
		
		count+=1;
		if(count % 100 == 0)
			println("--\> Processed <count> units so far..");
	}
	
	println("--\> Processed <count> units in total");
	return result;
}