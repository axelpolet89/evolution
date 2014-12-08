module modules::CloneDetector

import Set;
import Map;
import List;
import String;
import util::Math;
import IO;

import helpers::Location;

alias cloc = tuple[loc, int, int];

// find duplicates, returns a map of duplicate lines along with a list of locations and start/end indices
public map[list[str], list[cloc]] FindClones (map[loc, list[lline]] allSources)
{
	blockSize = 6;
	
	map[list[str], cloc] blocks = (); 
	map[list[str], list[cloc]] clones = ();
	
	int count = 0;
	
	for(key <- allSources)
	{	
		count += 1;

		curSource = [s | c <- allSources[key], s := <trim(c[0]),c[1],c[2]>];
		
		if(size(curSource) < blockSize)
			continue;
		
		//keep track of previous matches for extension
		matched = false;
		cloc prevMatchL = <key, -1, -1>;
		cloc prevMatchR = <key, -1, -1>;
		list[str] prevBlock = [];
		
		//used for interpolating in existing exstensions
		map[loc, list[tuple[cloc, cloc]]] curMatches = (); 
		
		for(i <- [0..size(curSource)-blockSize])
		{				
			//list[lline] blockInfo = source[i..(i+blockSize)];
			list[str] block = [ll[0] | ll <- curSource[i..(i+blockSize)]];
			
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
					if(prevBlock notin clones)
					{
						clones[prevBlock] = [GetActualLocation(prevMatchL, allSources[prevMatchL[0]])] + [GetActualLocation(prevMatchR, curSource)];
					}
					else
					{
						clones[prevBlock] += [GetActualLocation(prevMatchR, curSource)];
					}
					
					//interpolate in existing matches (in case extensions also have submatches with other code)
					loc refMatch = prevMatchL[0];
					if(refMatch in curMatches)
					{
						for(cm <- [cm | cm <- curMatches[refMatch], prevMatchL[1] > cm[0][1] && prevMatchL[2] <= cm[0][2]])
						{
							cloc refLoc = cm[0];
							cloc otherLoc = cm[1];
							cloc extraClone = <otherLoc[0], otherLoc[1] + (prevMatchL[1]-refLoc[1]),otherLoc[2] - (refLoc[2]-prevMatchL[2])>;
							clones[prevBlock] += [GetActualLocation(extraClone, allSources[extraClone[0]])];							
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
				cloc curMatch = <key,i,i+blockSize>;

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
			println("<count> compilation units checked for clones so far..");
	}
	
	println("--\> checked <count> compilation unites for clones in total");
	
	return clones;
}

public int GetCloneTotal(map[list[str], list[cloc]] ccs)
{
	clones = SortClonesByUnit(ccs);
	clones = FilterDoubles(clones);
		
	num total = 0;
	for(cs <- range(clones))		
		total += sum([len | c <- cs, len := (c[2]-c[1]+1)]);
		
	return toInt(total);
}

private map[str, list[cloc]] FilterDoubles(map[str, list[cloc]] clsByUnit)
{
	result = clsByUnit;
	
	for(key <- result)
	{
		clones = result[key];
		for(clone <- clones)
		{
			//check if any wrappers exist that cover this clone entirely
			list[cloc] cloneWrappers = [cw | cw <- clones, (clone[1] > cw[1] && clone[2] <= cw[2]) 
															|| (clone[1] >= cw[1] && clone[2] < cw[2])];
			if(size(cloneWrappers) > 0)
				result[key] = result[key] - clone;
		}
	}
	
	return result;
}

private map[str, list[cloc]] SortClonesByUnit(map[list[str], list[cloc]] ccs)
{
	map[str, list[cloc]] sccs = ();
	
	//transform cloneclasses into sorted comp-unit -> clones
	for(key <- ccs)
	{
		list[cloc] cclass = ccs[key];
		for(c <- cclass)
		{
			str cUri = c[0].uri;
			if(cUri notin sccs)
			{
				sccs[cUri] = [c];
			}
			else
			{
				sccs[cUri] += [c];
			}
		}
	}
	
	//sort clones ascending per comp-unit 
	for(key <- sccs)
		sccs[key] = sort(sccs[key], bool(cloc a, cloc b){ return (a[2]-a[1]) < (b[2]-b[1]); });
		
	return sccs;
}

private cloc GetActualLocation(cloc orig, list[lline] source)
{
	lline s = source[orig[1]];		//get original lline for the begin of match
	lline e = source[orig[2]];		//get original lline for the end of match
	lline n = source[orig[2]+1];	//get original lline for the next match
	length = n[2]-s[2];				//length in chars/bytes	
	return <ModifyLocation(orig[0],s[2],length,s[1],e[1]), orig[1], orig[2]>;
}


/*
	Unit test
*/
public tuple[bool, str] TstCloneSortFilter(tuple[int,map[loc,list[lline]]] source)
{
	map[list[str], list[cloc]] ccs = FindClones(source[1]);
	map[str, list[cloc]] clones = SortClonesByUnit(ccs);
	
	int lastSize = 0;
	for(key <- clones)
	{
		fst = head(clones[key]);
		lastSize = fst[2] - fst[1];
		for(c <- clones[key])
		{
			curSize = c[2]-c[1]; 
			if(curSize < lastSize)
				return<false, "at SortClonesByUnit()\r\nclones for unit <key> not sorted by ascending:\r\n<clones[key]>">;
			lastSize = curSize;
		}
	}
	
	clones = FilterDoubles(clones);
	
	for(key <- clones)
	{
		list[cloc] curClones = clones[key];
		for(c <- clones[key])
		{
			if(size([cw | cw <- curClones, (c[1] > cw[1] && c[2] <= cw[2]) || (c[1] >= cw[1] && c[2] < cw[2])]) > 0)
				return<false, "at FilterDoubles()\r\nthere exist a clone <c>\r\nfor unit <key> that is wrapped by larger clones:\r\n<curClones>">;
		}
	}
	
	return <true, "">;
}