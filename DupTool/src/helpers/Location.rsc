module helpers::Location

import List;
import String;

alias lline = tuple[str,int,int];

public loc ModifyLocation(loc source, int offset, int length, int begin, int end)
{	
	loc result = source;
	result.offset = offset;
	result.length = length;
	result.begin = <begin,0>;
	result.end = <end,0>;
	return result;
}

public list[lline] GetLineDescriptors(list[str] lines)
{
	list[lline] lds = [];
	
	int offset = 0;
	for(i <- [0..size(lines)])
	{	
		str line = lines[i];					
		lds += <line,i+1,offset>;
		offset += size(line) + 2;
	}
	
	return lds;
}