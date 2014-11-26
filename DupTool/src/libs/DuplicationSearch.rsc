module libs::DuplicationSearch

import Map;
import List;
import String;
import IO;

// return count of total lines found as duplicate
public int CountDuplicateLines(map[loc, list[str]] compilationUnits)
{
	map[list[str], list[tuple[loc, int, int]]] duplicates = FindDuplicates(compilationUnits);
	
	int dupLoc = 0;
	for(k <- duplicates)
		dupLoc += size(k) * size(duplicates[k]) + size(k);

	return dupLoc;
}

// find duplicates, returns a map of duplicate lines along with a list of locations and start/end indices
public map[list[str], list[tuple[loc, int, int]]] FindDuplicates (map[loc, list[str]] compilationUnits)
{
	int blockSize = 6;
	
	map[list[str], tuple[loc, int, int]] blocks = (); 
	map[list[str], list[tuple[loc, int, int]]] dups = ();
	
	int count = 0;
	for(key <- compilationUnits)
	{
		count += 1;

		list[str] source = [trim(c) | c <- compilationUnits[key]];
		
		if(size(source) < blockSize)
			continue;
		
		//used for extending found duplicates
		int prevEnd = 0;
		list[str] prevBlock = [];
		
		for(i <- [0..size(source)-blockSize])
		{				
			list[str] block = source[i..(i+blockSize)];

			if(block notin blocks)
			{
				//no duplicate, just remember
				blocks[block] = <key, i, i+blockSize>;
			}
			else
			{
				//extend found duplicate if it's end index is 1 more than the previous' block end index
				if(i-1 == prevEnd)
				{
					//remove old block from duplicates
					if(size(dups[prevBlock]) == 1)
						dups = delete(dups, prevBlock);
					else
					{
						list[tuple[loc,int,int]] matches = dups[prevBlock];
						dups[prevBlock] = delete(matches, size(matches) - 1);
					}
					
					//extend previous block with last line of current block
					list[str] extension = prevBlock + block[5];
					
					//add extended duplicate to map, (if another duplicate of same block exists, add to to list)
					if(extension in dups)
						dups[extension] += [<key,prevEnd-blockSize, i>];
					else
						dups[extension] = [<key,prevEnd-blockSize, i>];
					
					//update previous block for (potential) further extension	
					prevBlock = extension;
				}
				else
				{
					//add duplicate to map, (if another duplicate of same block exists, add to to list)
					if(block in dups)
						dups[block] += [ <key,i,i+blockSize> ];
					else
						dups[block] = [<key,i,i+blockSize>];
				
					//update previous block for (potential) further extension
					prevBlock = block;
				}
				
				prevEnd = i;
			}			
		}
		
		if(count % 10 == 0)
			println("<count> compilation units checked for duplications so far..");
	}
	
	println("--\> checked <count> compilation unites for duplications in total");
	
	return dups;
}
