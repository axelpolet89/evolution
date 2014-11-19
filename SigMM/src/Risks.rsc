module Risks

import lang::java::m3::Registry;
import util::Math;

// Low | Moderate | High | VeryHigh
data Risk = Low() | Mod() | High() | Very();

//return a risk value for unit's size/complexity
private Risk RiskForUnit(int complexity)
{
	if(complexity > 50)
		return Very();
	
	if(complexity > 21)
		return High();
	
	if(complexity > 11)
		return Mod();
	
	return Low();
}

//calculatie relative percentage of low, moderate, high, very high risks to total LOC
private map[Risk, int] ComputeRelativeRisks(map[Risk, int] risks, int totalLOC)
{
	map[Risk, int] relativeRisks = (Low():0, Mod():0, High():0, Very():0);
	for(r <- risks)
	{
		relativeRisks[r] += GetPercentage(risks[r], totalLOC);
	}
	return relativeRisks;
}

//return risks for unit sizes. Relative to given total Lines of Code 
public map[Risk, int] RisksForUnitSizes(map[loc, int] unitSizes, int totalLOC)
{
	map[Risk, int] risks = (Low():0, Mod():0, High():0, Very():0);
	for(key <- unitSizes)
	{
		int size = unitSizes[key];
		risks[RiskForUnit(size)] += size;
	}	
	return ComputeRelativeRisks(risks, totalLOC);
}

//return risks for unit complexities using unit sizes. Relative to given total Lines of Code 
public map[Risk, int] RisksForUnitComplexities(map[loc, int] unitComplexities, map[loc, int] unitSizes, int totalLOC)
{
	map[Risk, int] risks = (Low():0, Mod():0, High():0, Very():0);
	for(key <- unitSizes)
	{
		loc method = resolveJava(key);
		risks[RiskForUnit(unitComplexities[method])] += unitSizes[key];
	}	
	return ComputeRelativeRisks(risks, totalLOC);
}

public int GetPercentage(int num1, int num2) = round(toReal(num1)/toReal(num2)*100);
