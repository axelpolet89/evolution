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
	if(source.scheme != "project")
		throw "ComputeLOC requires a source location with a project scheme! Given source: <source>";
		
	list[str] fileLines = readFileLines(source);
	
	for(d <- docs)
	{
		//indices on which documentation starts/ends in 'source' array 
		int sIdx = indexOf([source.begin.line..source.end.line], d.begin.line);
		int eIdx = indexOf([source.begin.line..source.end.line], d.end.line);
		
		for(lineIdx <- [sIdx..eIdx + 1])
		{
			list[int] chars = chars(fileLines[lineIdx]);
			int sCol = 0;
			int eCol = size(chars);
			
			if(lineIdx == sIdx)
				sCol = d.begin.column;
			if(lineIdx == eIdx)
				eCol = d.end.column;

			//replace all comment lines with whitespace (32 is ASCII for space)
			for(colIdx <- [sCol..eCol])
				chars[colIdx] = 32;

			fileLines[lineIdx] = stringChars(chars);
		}
	}							
		
	return size( [line | line <- fileLines, trim(line) != "" ] );
}