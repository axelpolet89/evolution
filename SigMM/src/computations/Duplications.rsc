module computations::Duplications

import Set;
import Map;
import List;
import IO;
import String;

public void MatchClasses(map[loc, list[str]] compilationUnits)
{
	int blockSize = 6;
	
	map[list[str], tuple[loc, int, int]] blocks = (); 
	map[list[str], list[tuple[loc, int, int]]] dups = ();
	
	int count = 0;
	for(key <- compilationUnits)
	{
		count += 1;
		
		list[str] source = [trim(c) | c <- compilationUnits[key]];
		println(key);
		
		int prevEnd = 0;
		list[str] prevBlock = [];
		for(i <- [0..size(source)-blockSize])
		{				
			list[str] block = source[i..(i+blockSize)];
			
			if(block notin blocks)
			{
				blocks[block] = <key, i, i+blockSize>;
			}
			else
			{
				if(i-1 == prevEnd)
				{
					dups = delete(dups, prevBlock);
					list[str] new = prevBlock + block[5];
					
					if(new in dups)
						dups[new] += <key,prevEnd-blockSize, i>;
					else
						dups[new] = [<key,prevEnd-blockSize, i>];
					
					//println("not normal: <size(dups)> <new>");	
					prevBlock = new;
				}
				else
				{
					if(block in dups)
						dups[block] += <key,i,i+blockSize>;
					else
						dups[block] = [<key,i,i+blockSize>];
				
					//println("normal: <size(dups)> <block>");
					prevBlock = block;
				}
				
				prevEnd = i;
			}			
		}
		
		
	
	}
	
	int dupLoc = 0;
	for(k <- dups)
	{
		dupLoc += size(k);
		println(k);
	}
	
	print(dupLoc);
}
