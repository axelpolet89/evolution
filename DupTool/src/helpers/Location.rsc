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

//check if location exists within range of another location 
public bool IsInRange(loc range, loc target)
{
	//target before range
	if(range.begin.line > target.end.line)
		return false;

	//target after range
	if(target.begin.line > range.end.line)
		return false;
	
	return true;
}

public int colBgn(loc source) = source.begin.column;
public int colEnd(loc source) = source.end.column;
public int lineBgn(loc source) = source.begin.line;
public int lineEnd(loc source) = source.end.line;