module volume::LinesOfCode

import IO;
import Set;
import List;
import lang::java::jdt::m3::Core;

public int TotalLOC(M3 model)
{
	int count = 0;
	for (c <- classes(model))
	{
		loc source = getOneFrom(model@declarations[c]);
		count += CountLines(source);
		//count += (1 + source.end.line - source.begin.line);
	}
	
	return count;
}

public int FieldsInClass(M3 model, loc class)
{
	return size([f | f <- model@containment[class], isField(f)]);
}


//Below first test on a 'file' schema, not using M3

public loc HomeDir()
{
	return |file:///c:/Users/Axel/Eclipse%20Projects/SigMM/subjects|;
}


public int TotalLinesOfCode2(loc homedir)
{
	if(!isDirectory(homedir))
		return 0;
	
	int count = 0;
	
	for(loc location <- homedir.ls)
	{
		if(isFile(location))
		{
			count += CountLines(location);			
		}
		else
		{
			count += TotalLinesOfCode(location);
		}
	}
	
	return count;
}

public int CountLines(loc file)
{
    if(exists(file))
    {
    	str contents = readFile(file);
    	int count = 0;
     	for(/((\*([^*]|[\r\n])*\/)|(\/\/.*)|(^\s*$))/ := contents)
     	//for(/^[\s*]$/ := contents)
     	{
       		count += 1;
  		}
  		return count; 	
    }
    
    return 0;
}