module computations::Duplications

import Map;
import List;
import IO;
import String;
import util::Math;

private int R = 256;
private int RandomPrime() = getOneFrom(primes(1024));

public void MatchClasses(map[loc, list[str]] classes)
{
	int blockIndex = 0;
	int blockSize = 6;
	for(key <- classes)
	{
		list[int] matches = [];
		list[str] current = classes[key];
		int max = size(current);
		
		//println("<max>, <blockIndex>");
		
		while(blockIndex + blockSize < max)
		{			
			list[str] block = current[blockIndex..blockIndex + blockSize];
			
			str search = "";
			for(l <- block)
				search += trim(l);
			
			for(key2 <- classes)
			{
				if(key == key2)
					continue;
					
				str target = "";
				for(l <- classes[key2])
					target += trim(l);
				
				list[int] newMatches = Match(search, target);
				
				if(size(newMatches) > 0)
				{
					println("match! search: <search>");
					println("match! target: <target>");
					println("<newMatches>\n");
					matches += newMatches;
					
					blockIndex += blockSize;
				}
			}
			
			blockIndex += 1;
		}
	}
}

public int search(str pattern, str text, int patHash, int Q, int pLength, int RM)
{
	//int Q = RandomPrime();
	//int pLength = size(pattern);
	int tLength = size(text);	
	
	//int RM = 1;
    //for (i <- [1..pLength])
       //RM = (R * RM) % Q;
       
    //int patHash = Hash(pattern, pLength, Q);
	
	if(tLength < pLength)
		return -1;


	int txtHash = Hash(text, pLength, Q);
	
 	//check for match at offset 0
    if ((patHash == txtHash) && check(text, pattern, pLength, 0))
        return 0;

    // check for hash match; if hash match, check for exact match
    for (i <- [pLength..tLength]) {
        // Remove leading digit, add trailing digit, check for match. 
        txtHash = (txtHash + Q - RM*charAt(text,i-pLength) % Q) % Q; 
        txtHash = (txtHash*R + charAt(text, i)) % Q; 

        // match
        int offset = i - pLength + 1;
        if ((patHash == txtHash) && check(text, pattern, pLength, offset))
            return offset;
    }
    
    return -1;
}

public list[int] Match(str pattern, str text)
{
	int Q = RandomPrime();
	int pLength = size(pattern);
	int tLength = size(text);	


	int RM = 1;
    for (i <- [1..pLength])
       RM = (R * RM) % Q;
       
    int patHash = Hash(pattern, pLength, Q);
	
	if(tLength < pLength)
		println("match textlength: <tLength>");
		
	list[int] matches = [];
	int startIndex = 0;
	int removedLength = 0;
	str subject = text;
	while(startIndex < size(text))
	{
		int result = search(pattern, subject, patHash, Q, pLength, RM);
		if(result >= 0)
		{
			matches += (removedLength + result);
			removedLength += result + pLength;
			subject = substring(subject, result + pLength);
		}
		if(result == -1)
		{
			startIndex = size(text);
		}
	}
		
	return matches;
}

private int Hash(str text, int patLength, int prime)
{
	int h = 0;
	for(i <- [0..patLength])
	{
		h = (R * h + charAt(text, i)) % prime;
	}
	return h;
}

 private bool check(str txt, str pat, int patLength, int i) {
    for (j <- [0..patLength]) 
        if (charAt(pat, j) != charAt(txt, i + j)) 
            return false; 
    return true;
}