module Risks

import lang::java::m3::Registry;
import util::Math;

data Risk = Low() | Mod() | High() | Very();

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

private map[Risk, int] ComputeRelativeRisks(map[Risk, int] risks, int volume)
{
	map[Risk, int] relativeRisks = (Low():0, Mod():0, High():0, Very():0);
	for(r <- risks)
	{
		relativeRisks[r] += round(toReal(risks[r])/toReal(volume)*100);
	}
	return relativeRisks;
}

public map[Risk, int] RisksForUnitSizes(map[loc, int] unitSizes, int volume)
{
	map[Risk, int] risks = (Low():0, Mod():0, High():0, Very():0);
	for(key <- unitSizes)
	{
		int size = unitSizes[key];
		risks[RiskForUnit(size)] += size;
	}	
	return ComputeRelativeRisks(risks, volume);
}

public map[Risk, int] RisksForUnitComplexities(map[loc, int] unitComplexities, map[loc, int] unitSizes, int volume)
{
	map[Risk, int] risks = (Low():0, Mod():0, High():0, Very():0);
	for(key <- unitSizes)
	{
		loc method = resolveJava(key);
		risks[RiskForUnit(unitComplexities[method])] += unitSizes[key];
	}	
	return ComputeRelativeRisks(risks, volume);
}
