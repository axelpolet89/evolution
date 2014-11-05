module volume::LinesOfCode

import IO;
import Set;
import lang::java::jdt::m3::Core;

public void TotalLOC(M3 model)
{
	int count = 0;
	for (c <- classes(model))
	{
		loc source = getOneFrom(model@declarations[c]);
		
		//regex very slow on large multi-line comments....
		//println("Class: <c>, Loc: <CountLOC(source)>");
		
		//SHOULD we use documentations from m3 
		//(ie remove all chars on lines that are included in the documentations from compiliation units and then count)?
		println("Class: <c>, Loc: <model@documentation>");
	}
	
	//return count;
}


public int CountLOC2(loc source)
{
	
}

public int CountLOC(loc source)
{
	int nonLOC = 0;
	str contents = readFile(source);
		
	//find multi-line comments, single-line comments and blanks lines
 	for(/((\/*([^*]|[\r\n]|(\*([^\/]|[\r\n])))*\/)|(\/\/.*)|([\s*]\r\n))/ := contents)
 	{
 		nonLOC += 1;
 	}
	
	//return (1 + source.end.line - source.begin.line) - nonLOC;
	return nonLOC; 	
}