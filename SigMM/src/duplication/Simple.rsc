module duplication::Simple

import Map;
import List;
import IO;

public int FindDuplicates(map[loc, list[str]] units)
{
	int result = 0;
	int minimum = 6;
	
	list[loc] prev = [];
	map[loc, map[loc, list[int]]] prevMatches = ();
	
	for(int m <- [minimum..100])
	{	
		map[loc, list[str]] unitsOfSize = (unit : units[unit] | unit <- units, size((units[unit])) == m);
		for(key <- unitsOfSize)
		{
			list[loc] excludes = [];
			if(key in prevMatches)
			{
				for(key2 <- prevMatches[key])
				{
					if(m in prevMatches[key][key3])
						excludes += key3;
				}
			}
		 
			list[loc] matches = Match(units[key], (unit : units[unit] | unit <- units, unit != key && unit notin excludes));
			prevMatches = updateMatches(prevMatches, matches, key, m);
			println(prevMatches);
			result += size(matches) * m;
		}
	}
	
	return result;
}

private map[loc, map[loc, list[int]]] updateMatches(map[loc, map[loc, list[int]]] current, list[loc] new, loc context, int size)
{
	
	if(context in current)
	{
	 	for(n <- new)
	 	{
	 		if(n in current[context])
	 		{
	 			current[context][n] += size;
	 		}
	 		else
	 		{
	 			current[context][n] = [size];
	 		}
	 	}
	}
	else
	{
		current[context] = ();
		for(n <- new)
	 	{
	 		if(n in current[context])
	 		{
	 			current[context][n] += size;
	 		}
	 		else
	 		{
	 			current[context][n] = [size];
	 		}
	 	}
	}
	
	return current;
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