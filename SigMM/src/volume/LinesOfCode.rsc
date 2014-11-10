module volume::LinesOfCode

import IO;
import List;
import Set;
import String;
import Relation;
import lang::java::m3::Core;
import lang::java::m3::Registry;

public void Volume(M3 model)
{
	int volume = 0; 
	set[loc] compUnits = { cnt | cnt <- domain(model@containment), cnt.scheme == "java+compilationUnit" };	
	
	int count = 0;
	int total = size(compUnits);
	
	for(compUnit <- compUnits)
	{
		count += 1;
		volume += ComputeLOC(resolveJava(compUnit), DocsForCU(compUnit, model));
		println("<count> of <total> - LOCSoFar: <volume>");
	}

	println("Volume: <volume>");
}

public void UnitSize(M3 model)
{
	set[loc] methods = methods(model);
	
	int total = size(methods);
	int count = 0;
	
	/*
	loc m = getOneFrom([mt | mt <- methods, contains(mt.uri, "Index/clear")]);
	loc mLocation = min(model@declarations[m]);
	loc mCompUnit = min({ dcl<0> | dcl <- model@declarations, dcl<0>.scheme == "java+compilationUnit" && dcl<1>.uri == mLocation.uri });
	set[loc] mDocs = {doc | doc <- DocsForCU(mCompUnit, model), IsInRange(mLocation, doc) };
	ComputeLOC(mLocation, mDocs);
	*/	
	
	for(m <- methods)
	{
		count += 1;
		loc mLocation = min(model@declarations[m]);
		loc mCompUnit = min({ dcl<0> | dcl <- model@declarations, dcl<0>.scheme == "java+compilationUnit" && dcl<1>.uri == mLocation.uri });
		set[loc] mDocs = {doc | doc <- DocsForCU(mCompUnit, model), IsInRange(mLocation, doc) };
		
		println("Unit <count> of <total>: <m>, UnitSize: <ComputeLOC(mLocation, mDocs)>");
	}
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


//return all docs for given computation unit
private set[loc] DocsForCU(loc cu, M3 model) = { docs<1> | docs <- model@documentation, docs<0> == cu };


//compute loc from given source (scheme: project)
private int ComputeLOC(loc source, set[loc] docs)
{
	//if(source.scheme != "project")
		//throw "ComputeLOC requires a source location with a project scheme! Given source: <source>";
		
	list[str] fileLines = readFileLines(source);
	list[int] lIndices = [source.begin.line..source.end.line + 1];		 //list is not inclusive
	
	//println("source: <source>");
	//println("docs: <docs>");
	//println("fileLines: <fileLines>");
	//println("lIndices : <min(lIndices)>-<max(lIndices)>");
	
	for(d <- docs)
	{	
		//indices on which documentation starts/ends in 'source' array 
		int sIdx = indexOf(lIndices, d.begin.line);
		int eIdx = indexOf(lIndices, d.end.line);
		
		//println("doc: <d>");
		//println("line from-to in 0-<size(fileLines)-1>: <sIdx>-<eIdx>");
		
		for(lineIdx <- [sIdx..eIdx + 1])
		{
			list[int] chars = chars(fileLines[lineIdx]);
			int sCol = 0;
			int eCol = size(chars);
			
			list[int] cIndices = [0..size(chars) + 1];
			//println("cIndices : <min(cIndices)>-<max(cIndices)>");
						
			if(lineIdx == sIdx)
				sCol = indexOf(cIndices, d.begin.column);
			if(lineIdx == eIdx)
				eCol = indexOf(cIndices, d.end.column);
			
			//println("line: <fileLines[lineIdx]>");
			//println("col from-to in 0-<size(chars)>: <sCol>-<eCol>");

			//replace all comment lines with whitespace (32 is ASCII for space)
			for(colIdx <- [sCol..eCol])
				chars[colIdx] = 32;
			
			//println("resultline: <stringChars(chars)>");
			
			fileLines[lineIdx] = stringChars(chars);
		}
		
		//println("final result: <fileLines>");
	}							
		
	return size( [line | line <- fileLines, trim(line) != "" ] );
}