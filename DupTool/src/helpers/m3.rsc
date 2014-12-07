module helpers::m3

import lang::java::jdt::m3::Core;
import Map;
import Set;
import IO;

public M3 GenerateM3(loc project)
{
	return createM3FromEclipseProject(project);
}

public loc FastResolveJava(M3 model, loc source)
{
	if (<source, jsource> <- model@declarations)
		return jsource;
}

//Get all documentation for M3, mapped on java file - javadoc? - documentation
public map[str,  set[loc]] ParseDocs(M3 model)
{
	map[str, set[loc]] docs = ();
	
	int total = size(model@documentation);
	println("--\> # of docs in M3: <total>");
	println("--\> started mapping docs on compilation-unit uri...");	
	
	int count = 0;
	for(doc <- model@documentation)
	{	
		str cUri;
		loc d = doc[0];
		if (<d, src> <- model@declarations)
    		cUri = src.uri;
      
		if(cUri in docs)
			docs[cUri] += { doc[1] };
		else
			docs[cUri] = { doc[1] };	
		
		count +=1;
		
		if(count % 100 == 0)
			println("--\> mapped <count> of <total> docs so far.."); 
	}
	
	println("--\> mapped documentation on <size(docs)> compilation-units!");
	return docs;
}