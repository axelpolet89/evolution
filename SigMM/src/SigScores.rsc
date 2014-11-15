module SigScores

import util::Math;

data Score = PP() | P() | N() | M() | MM();
data Risk = Low() | Mod() | High() | Very();

public Risk RiskForUnit(int complexity)
{
	if(complexity > 50)
		return Very();
	
	if(complexity > 21)
		return High();
	
	if(complexity > 11)
		return Mod();
	
	return Low();
}

public Score GetVolumeScore(int volume)
{
	if(volume > 1310000)
		return MM();
	
	if(volume > 655000)
		return M();
	
	if(volume > 246000)
		return N();
	
	if(volume > 66000)
		return P;
	
	return PP();
}

public Score GetUnitScore(map[Risk, int] risks)
{
	if(risks[Very()] > 5 || risks[High()] > 15 || risks[Mod()] > 50)
		return MM();
	
	if(risks[High()] > 10 || risks[Mod()] > 40)
		return M();
		
	if(risks[High()] > 5 || risks[Mod()] > 30)
		return N();
	
	if(risks[Mod()] > 25)
		return P();
		
	return PP(); 
}

public Score MergeScores(list[Score] scores)
{
	Score result = N();
	
	for(r <- [score | score <- scores, score != N()])
	{
		real a = (toReal(ToInt(result)) + toReal(ToInt(r))) / 2;
		if(a > 3.0)
			result = FromInt(floor(a));
		else
			result = FromInt(ceil(a));
	}
	
	return result;
}

public str ToString(Score s)
{
	switch(s)
	{
		case PP():
			return "++";
		case P():
			return "+";
		case N():
			return "o";
		case M():
			return "-";
		case MM():
			return "--";
	}
}

public int ToInt(Score s)
{
	switch(s)
	{
		case PP():
			return 1;
		case P():
			return 2;
		case N():
			return 3;
		case M():
			return 4;
		case MM():
			return 5;
	}
}

private Score FromInt(int i)
{
	switch(i)
	{
		case 1:
			return PP();
		case 2:
			return P();
		case 3:
			return N();
		case 4:
			return M();
		case 5:
			return MM();
	}
}