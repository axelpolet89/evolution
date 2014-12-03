module libs::DuplicationSearch

import Set;
import Map;
import List;
import String;
import util::Math;
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

public map[str, list[duploc]] GetSortedCcs(map[list[str], list[duploc]] ccs)
{
	map[str, list[duploc]] sccs = ();
	
	//transform cloneclasses into sorted comp-unit -> clones
	for(key <- ccs)
	{
		list[duploc] dup = ccs[key];
		for(d <- dup)
		{
			str dUri = d[0].uri;
			if(dUri notin sccs)
			{
				sccs[dUri] = [d];
			}
			else
			{
				sccs[dUri] += [d];
			}
		}
	}
	
	//sort clones descending per comp-unit 
	for(key <- sccs)
		sccs[key] = sort(sccs[key], bool(duploc a, duploc b){ return (a[2]-a[1]) > (b[2]-b[1]); });
		
	return sccs;
}

public int GetCloneTotal(map[list[str], list[duploc]] ccs)
{
	map[str, list[duploc]] sccs = GetSortedCcs(ccs);
	
	for(key <- sccs)
	{
		//start with smalles clone in comp-unit
		list[duploc] dup = reverse(sccs[key]);
		for(d <- dup)
		{
			//check if any wrappers exist that cover this clone entirely
			list[duploc] cloneWrappers = [pc | pc <- dup, (d[1] > pc[1] && d[2] <= pc[2]) 
															|| (d[1] >= pc[1] && d[2] < pc[2])];
			if(size(cloneWrappers) > 0)
				sccs[key] = sccs[key] - d;
		}
	}
	
	num total = 0;
	for(cs <- range(sccs))		
		total += sum([len | c <- cs, len := (c[2]-c[1]+1)]);
		
	return toInt(total);
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
					//adjust last addition
					prevMatchL = <prevMatchL[0],prevMatchL[1],prevMatchL[2]-1>;
					prevMatchR = <prevMatchR[0],prevMatchR[1],prevMatchR[2]-1>;
					
					//store left/right hand side in dups or just right hand
					if(prevBlock notin dups)
					{
						dups[prevBlock] = [GetActualLocation(prevMatchL, compilationUnits[prevMatchL[0]])] + [GetActualLocation(prevMatchR, source)];
					}
					else
					{
						dups[prevBlock] += [GetActualLocation(prevMatchR, source)];
					}
					
					//interpolate in existing matches (in case extensions also have submatches with other code)
					loc refMatch = prevMatchL[0];
					if(refMatch in curMatches)
					{
						for(cm <- [cm | cm <- curMatches[refMatch], prevMatchL[1] > cm[0][1] && prevMatchL[2] <= cm[0][2]])
						{
							duploc refLoc = cm[0];
							duploc otherLoc = cm[1];
							duploc extraDup = <otherLoc[0], otherLoc[1] + (prevMatchL[1]-refLoc[1]),otherLoc[2] - (refLoc[2]-prevMatchL[2])>;
							dups[prevBlock] += [GetActualLocation(extraDup, compilationUnits[extraDup[0]])];							
						}
					}
					else
					{		
						curMatches[refMatch] = [];
					}
					
					//keep track of current matches for this compilation unit, used for interpolation
					if(prevMatchL[0] != prevMatchR[0])
						curMatches[refMatch] += [<prevMatchL, prevMatchR>];
					
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
	lline s = source[orig[1]];		//get original lline for the begin of match
	lline e = source[orig[2]];		//get original lline for the end of match
	lline n = source[orig[2]+1];	//get original lline for the next match
	int length = n[2]-s[2];			//length in chars/bytes	
	return <ModifyLocation(orig[0],s[2],length,s[1],e[1]), orig[1], orig[2]>;
}