module computations::LinesOfCode

import IO;
import String;
import List;
import Set;
import Map;
import Relation;
import lang::java::m3::Core;
import lang::java::m3::Registry;

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

		cuSizes[cUnit] = TrimWhiteLines(lines);
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
		list[str] lines = ParseSourceNoDocs(mLoc, {doc | doc <- docs[mLoc.uri][false], IsInRange(mLoc, doc)});		
		int unitLOC = size(TrimWhiteLines(lines));
				
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
		
		if(eIdx == sIdx)
		{
			str line = fileLines[sIdx];
			int sCol = 0;			
			list[int] cIndices = [sCol..size(line) + 1];
			
			//get correct startindex
			if(sIdx == 0)
				sCol = d.begin.column - source.begin.column;
			else 
				sCol = indexOf(cIndices, d.begin.column);
				
			int eCol = indexOf(cIndices, d.end.column);
			if(eCol == -1) //fix: leading tabs/spaces are not accounted for by readFileLines
				eCol = indexOf(cIndices, d.end.column - d.begin.column);
				
			fileLines[sIdx] =  ReplaceWithWhiteSpace(line, sCol, eCol);
		}		
		else
		{
			//first docline
			str line = fileLines[sIdx];		
			int sCol = 0;
			int eCol = size(line);
			
			//get correct startindex
			if(sIdx == 0)
				sCol = d.begin.column - source.begin.column;
			else 
				sCol = indexOf([sCol..eCol + 1], d.begin.column);
				
			fileLines[sIdx] = ReplaceWithWhiteSpace(line, sCol, eCol);
					
			//middle doclines	
			for(idx <- [sIdx+1..eIdx])
				fileLines[idx] = "";
			
			//last docline
			line = fileLines[eIdx];	
			sCol = 0;		
			eCol = indexOf([sCol..size(line) + 1], d.end.column);
			
			fileLines[eIdx] = ReplaceWithWhiteSpace(line, sCol, eCol);
		}
	}	
		
	return fileLines;						
}

private list[str] TrimWhiteLines(list[str] lines) = [line | line <- lines, trim(line) != ""];

private str ReplaceWithWhiteSpace(str line, int sCol, int eCol) = substring(line, 0, sCol) + substring(line, eCol);