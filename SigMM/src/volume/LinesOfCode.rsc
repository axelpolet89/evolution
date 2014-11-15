module volume::LinesOfCode

import IO;
import String;
import List;
import Set;
import Map;
import Relation;
import lang::java::m3::Core;
import lang::java::m3::Registry;

public void Volume(M3 model, map[str, set[loc]] docs)
{
	set[loc] compUnits = { d | d <- domain(model@declarations), isCompilationUnit(d)};
		
	int volume = 0; 		
	int count = 0;
	int total = size(compUnits);
	
	for(c <- compUnits)
	{
		count += 1;
		loc cLoc = resolveJava(c);
		volume += ComputeLOC(cLoc, docs[cLoc.uri]);
		
		if(count % 5 == 0)
		{
			println("<count> of <total> - LOCSoFar: <volume>");
		}
	}

	println("Volume: <volume>");
}

public map[loc, int] ComputeUnitSizes(M3 model, map[str, set[loc]] docs)
{	
	map[loc, int] result = ();
	count = 0;
		
	//loop methods
	for(m <- methods(model))
	{
		loc mLoc = resolveJava(m);
		result += (m : ComputeLOC(mLoc, {doc | doc <- docs[mLoc.uri], IsInRange(mLoc, doc)}));
		
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


//compute loc from given source (scheme: project)
private int ComputeLOC(loc source, set[loc] docs)
{
	list[str] fileLines = readFileLines(source);
	list[int] lIndices = [source.begin.line..source.end.line + 1];		 //list is not inclusive
	
	//println("source: <source>");
	//println("docs: <docs>");
	
	for(d <- docs)
	{	
		//indices on which documentation starts/ends in 'source' array 
		int sIdx = indexOf(lIndices, d.begin.line);
		int eIdx = indexOf(lIndices, d.end.line);
		
		for(lineIdx <- [sIdx..eIdx + 1])
		{
			list[int] chars = chars(fileLines[lineIdx]);
			int sCol = 0;
			int eCol = size(chars);
			
			list[int] cIndices = [sCol..eCol + 1];
						
			if(lineIdx == 0)
			{
				//documentation at begin of source, begin on first char of source
				sCol = d.begin.column - source.begin.column;
			}
			else if(lineIdx == sIdx) 
			{
				//first line of documentation; get correct startindex
				sCol = indexOf(cIndices, d.begin.column); 
			}
				
			if(lineIdx == eIdx)
			{
				//last line of documentation; get correct endindex
				eCol = indexOf(cIndices, d.end.column);
			}

			//replace all comment lines with whitespace (32 is ASCII for space)
			for(colIdx <- [sCol..eCol])
				chars[colIdx] = 32;
			
			fileLines[lineIdx] = stringChars(chars);
		}
	}							
		
	return size( [line | line <- fileLines, trim(line) != "" ] );
}



/*==========================================================================*/
/* OLD STUFF */

public void UnitSizeEx(M3 model, map[str, set[loc]] docs)
{	
	set[loc] allMethods = methods(model);
	int total = size(allMethods);
	int count = 0;
		
	//loop methods
	for(m <- allMethods)//{mt | mt <- methods(model), contains(mt.uri, "Join/isExpressionsFromThisRow")})
	{
		count+=1;
		
		//get file location of method
		loc mLoc = resolveJava(m);
		
		//compute
		println("Unit <count> of <total>: <m>, UnitSize: <ComputeLOC(mLoc, {doc | doc <- docs[mLoc.uri], IsInRange(mLoc, doc)})>");
	}
}

//compute loc from given source (scheme: project)
private int ComputeLOCDebug(loc source, set[loc] docs)
{
	//if(source.scheme != "project")
		//throw "ComputeLOC requires a source location with a project scheme! Given source: <source>";
		
	list[str] fileLines = readFileLines(source);
	list[int] lIndices = [source.begin.line..source.end.line + 1];		 //list is not inclusive
	
	println("source: <source>");
	println("docs: <docs>");
	println("fileLines: <fileLines>");
	println("lIndices : <min(lIndices)>-<max(lIndices)>");
	
	for(d <- docs)
	{	
		//indices on which documentation starts/ends in 'source' array 
		int sIdx = indexOf(lIndices, d.begin.line);
		int eIdx = indexOf(lIndices, d.end.line);
		
		println("doc: <d>");
		println("line from-to in 0-<size(fileLines)-1>: <sIdx>-<eIdx>");
		
		for(lineIdx <- [sIdx..eIdx + 1])
		{
			list[int] chars = chars(fileLines[lineIdx]);
			int sCol = 0;
			int eCol = size(chars);
			
			list[int] cIndices = [sCol..eCol + 1];
			println("cIndices : <min(cIndices)>-<max(cIndices)>");
			println("cBegin: <d.begin.column -1>, cEnd: <d.end.column>");
			
			if(lineIdx == 0)
			{
				//documentation at begin of source, begin on first char of source
				sCol = d.begin.column - source.begin.column;
			}
			else if(lineIdx == sIdx) 
			{
				//first line of documentation; get correct startindex
				sCol = indexOf(cIndices, d.begin.column); 
			}
				
			if(lineIdx == eIdx)
			{
				//last line of documentation; get correct endindex
				eCol = indexOf(cIndices, d.end.column);
			}
			
			println("cBegin: <sCol>, cEnd: <eCol>");
			
			println("line: <fileLines[lineIdx]>");
			println("col from-to in 0-<size(chars)>: <sCol>-<eCol>");

			//replace all comment lines with whitespace (32 is ASCII for space)
			for(colIdx <- [sCol..eCol])
				chars[colIdx] = 32;
			
			println("resultline: <stringChars(chars)>");
			
			fileLines[lineIdx] = stringChars(chars);
		}
		
		println("final result: <fileLines>");
	}							
		
	return size( [line | line <- fileLines, trim(line) != "" ] );
}