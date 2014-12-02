module libs::LocationHelpers

import libs::Aliasses;

import List;
import String;

alias lline = tuple[str,int,int];

public loc ModifyLocation(loc source, int offset, int length, int begin, int end)
{
	loc result = source;
	result.offset = offset;
	result.length = length;
	result.begin = <begin,0>;
	result.end = <end,10>;
	return result;
}

public list[lline] GetLineDescriptors(list[str] lines)
{
	list[lline] lds = [];
	
	int offset = 0;
	for(i <- [0..size(lines)])
	{	
		str line = lines[i];		
		
		int extra = 1;
		if(startsWith(line,"\t"))
			extra += 1;
		if(endsWith(line,"\t"))
			extra += 1;
		if(trim(line) == "")
			extra -= 1;
			
		lds += <line,i+1,offset>;
		offset += size(line) + extra;
	}
	
	return lds;
}