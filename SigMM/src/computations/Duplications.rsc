module computations::Duplications

import Map;
import List;
import IO;

public int FindDuplicates(map[loc, list[str]] units)
{
	int result = 0;
	int minimum = 6;
	
	list[loc] prev = [];
	
	for(int m <- [minimum..100])
	{	
		map[loc, list[str]] unitsOfSize = (unit : units[unit] | unit <- units, size((units[unit])) == m);
		for(key <- unitsOfSize)
		{
			list[loc] matches = Match(units[key], (unit : units[unit] | unit <- units, unit != key));
			result += size(matches) * m;
		}
	}
	
	return result / 2;
}

private list[loc] Match(list[str] search, map[loc, list[str]] units)
{
	list[loc] matches = [];
	int idx = 0;
	for(key <- units)
	{
		for(s <- search)
		{
			if(s == units[key][idx])
			{
				println("matched <s> with <units[key][idx]>!");
				idx += 1;
			}
		}
		
		if(idx == size(search))
		{
			println("block match!: <idx>, <size(search)>");
			matches += key;
		}
	}
	
	return matches;
}