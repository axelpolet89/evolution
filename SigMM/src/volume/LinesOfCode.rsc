module volume::LinesOfCode

import IO;
import List;
import Set;
import String;
import Relation;
import ListRelation;
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
	int total = size(methods(model));
	int count = 0;
	set[loc] compUnits = { cnt | cnt <- domain(model@containment), isCompilationUnit(cnt) };
	
	/*
	loc m = getOneFrom([mt | mt <- methods(model), contains(mt.uri, "NoFromResult/isExpressions")]);
	loc mLocation = min(model@declarations[m]);
	loc mCompUnit = min({ dcl<0> | dcl <- model@declarations, dcl<0>.scheme == "java+compilationUnit" && dcl<1>.uri == mLocation.uri });
	set[loc] mDocs = {doc | doc <- DocsForCU(mCompUnit, model), IsInRange(mLocation, doc) };
	ComputeLOC(mLocation, mDocs);
	*/

		/*
	
	map[str, set[loc]] compDocs = ();
	
	for(compUnit <- compUnits)
	{
		compDocs += (resolveJava(compUnit).uri : DocsForCU(compUnit, model));		
	}
	println("docs for cu resolved: <size({k | k <- compDocs})>");
	
	for(m <- methods(model))
	{
		loc mLoc = resolveJava(m);
		set[loc] mDocs = compDocs[mLoc.uri];
		mDocs += DocsForCU(m, model);
		set [loc] docsInRange = {doc | doc <- mDocs, IsInRange(mLoc, doc)};
		println("Unit <count> of <total>: <m>, UnitSize: <ComputeLOC(mLoc, docsInRange)>");
	}
	*/
	
	//top-down
	for(compUnit <- compUnits)
	{
		set[loc] docs = DocsForCU(compUnit, model);	
				
		for(c <- getClassRecur(model, { cnt<1> | cnt <- model@containment, cnt<0> == compUnit }))
		{
			for(m <- {cnt<1> | cnt <- model@containment, cnt<0> == c, isMethod(cnt<1>) })
			{
				loc mLoc = resolveJava(m);
				println("Unit <count> of <total>: <m>, UnitSize: <ComputeLOC(mLoc, {doc | doc <- docs, IsInRange(mLoc, doc)})>");
			}
		}		
	}
}


//check for inner classes
private set[loc] getClassRecur(M3 model, set[loc] classes)
{
	set[loc] innerClasses = { cnt<1> | cnt <- model@containment, isClass(cnt<1>) && cnt<0> in classes };
	if(size(innerClasses) == 0)
		return classes;
	
	return (classes + getClassRecur(model, innerClasses));
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
private set[loc] DocsForCU(loc source, M3 model) = { docs<1> | docs <- model@documentation, docs<0> == source };


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
			//println("cBegin: <d.begin.column>, cEnd: <d.end.column>");
						
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