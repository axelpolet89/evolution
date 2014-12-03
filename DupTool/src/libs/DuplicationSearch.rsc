module libs::DuplicationSearch

import Set;
import Map;
import List;
import String;
import IO;

import libs::LocationHelpers;

alias duploc = tuple[loc, int, int];

// return count of total lines found as duplicate
public int CountDuplicateLines(map[loc, list[lline]] compilationUnits)
{
	map[list[str], list[duploc]] duplicates = FindDuplicates(compilationUnits);
	
	int dupLoc = 0;
	for(k <- duplicates)
	{
		println("class: <duplicates[k]>\nlines: <k>");
		dupLoc += size(k) * size(toSet(duplicates[k]));// + size(k);
		
		if(size(toSet(duplicates[k])) != size(duplicates[k]))
			println("error!");
	}

	return dupLoc;
}

// find duplicates, returns a map of duplicate lines along with a list of locations and start/end indices
public map[list[str], list[duploc]] FindDuplicates (map[loc, list[lline]] compilationUnits)
{
	int blockSize = 6;
	
	map[list[str], duploc] blocks = (); 
	map[list[str], list[duploc]] dups = ();
	
	int count = 0;
	
	for(key <- compilationUnits)
	{	
		count += 1;

		list[lline] source = [s | c <- compilationUnits[key], s := <trim(c[0]),c[1],c[2]>];
		
		if(size(source) < blockSize)
			continue;
		
		//keep track of previous matches for extension
		bool matched = false;
		duploc prevMatchL = <key, -1, -1>;
		duploc prevMatchR = <key, -1, -1>;
		list[str] prevBlock = [];
		
		//used for interpolating in existing exstensions
		map[loc, list[tuple[duploc, duploc]]] curMatches = (); 
		
		for(i <- [0..size(source)-blockSize])
		{				
			//list[lline] blockInfo = source[i..(i+blockSize)];
			list[str] block = [ll[0] | ll <- source[i..(i+blockSize)]];
			
			if(block notin blocks)
			{
				//no duplicate, just remember
				blocks[block] = <key, i, i+blockSize>;
				
				//store prevMatchL(eft) prevMatchR(ight) pair
				if(matched)
				{
					if(prevBlock notin dups)
					{
						dups[prevBlock] = [GetActualLocation(prevMatchL, compilationUnits[prevMatchL[0]])] + [GetActualLocation(prevMatchR, source)];
					}
					else
					{
						dups[prevBlock] += [GetActualLocation(prevMatchR, source)];
					}
					
					//reset
					prevMatchL = <key, -1, -1>;
		 			prevMatchR = <key, -1, -1>;
					prevBlock = [];
					matched = false;	
				}
			}
			else
			{
				matched = true;
				duploc curMatch = <key,i,i+blockSize>;

				//extend search if this match is one line further than previous match
				if(prevMatchR[2] == curMatch[2]-1)
				{
					prevMatchL = <prevMatchL[0],prevMatchL[1],prevMatchL[2]+1>;
					prevMatchR = <prevMatchR[0],prevMatchR[1],prevMatchR[2]+1>;
					prevBlock = prevBlock + block[5];					
				}
				else
				{
					prevMatchL = blocks[block];
					prevMatchR = curMatch;
					prevBlock = block;
				}
			}
		}
		
		if(count % 10 == 0)
			println("<count> compilation units checked for duplications so far..");
	}
	
	println("--\> checked <count> compilation unites for duplications in total");
	
	return dups;
}

private duploc GetActualLocation(duploc orig, list[lline] source)
{
	lline s = source[orig[1]];		//start of match, e[2] is offset
	lline e = source[orig[2]-1];	//end of match e[1] is linenr
	int length = e[2]-s[2]+2;		//length in chars/bytes
	return <ModifyLocation(orig[0],s[2],length,s[1],e[1]), orig[1], orig[2]>;
}