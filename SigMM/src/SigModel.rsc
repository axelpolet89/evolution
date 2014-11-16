module SigModel

import SigScores;
import volume::LinesOfCode;
import complexity::Cyclomatic;

import IO;
import DateTime;
import Set;
import Map;
import Relation;
import List;
import util::Math;
import lang::java::jdt::m3::Core;
import lang::java::m3::Registry;

public loc prjDude = |project://Dude|;
public loc prjSS = |project://SmallSql|;
public loc prjHS = |project://hsqldb|;

//const strings for SIG scores on volume, complexity, duplicates, unit sizes, unit tests
str V = "V";
str CC = "CC";
str D = "D";
str US = "US";
str UT = "UT";

//Main call to compute SIG metrics
public void ComputeMetrics(loc project)
{
	println("started building M3 model...");
	M3 model = createM3FromEclipseProject(project);
	println("M3 model built!\n");	
	
	println("started gathering docs...");
	map[str, map[bool, set[loc]]] docs = ParseDocs(model);
	println("docs gathered!\n");
	
	println("started computing volume...");
	datetime s1 = now();
	int volume = 24221;//Volume(model, docs);
	datetime e1 = now();
	println("volume computed!\n");
	
	println("started computing unit sizes...");
	datetime s2 = now();
	map[loc, int] unitSizes = ComputeUnitSizes(model, docs);
	datetime e2 = now();
	println("unit sizes computed!\n");
	
	println("started computing unit complexities...");
	datetime s3 = now();
	map[loc, int] unitComplexities = ComputeUnitComplexities(project);		
	datetime e3 = now();	
	println("unit complexities computed!\n");

	
	int unitsLOC = 0;
	for(key <- unitSizes)
		unitsLOC += unitSizes[key];
	
	map[Risk, int] unitSizeRisks = ComputeRelativeRisks(RisksForUnitSizes(unitSizes), unitsLOC);
	map[Risk, int] unitComplexityRisks = ComputeRelativeRisks(RisksForUnitComplexities(unitComplexities, unitSizes), unitsLOC);
	
	println("Unit size risks:");
	PrintRisks(unitSizeRisks);
	println("Unit complexity risks:");
	PrintRisks(unitComplexityRisks);
	
	
	Score scoreV = GetVolumeScore(volume);
	Score scoreCC = GetUnitScore(unitComplexityRisks);
	Score scoreD = N();
	Score scoreUS = GetUnitScore(unitSizeRisks);
	Score scoreUT = N();
	
	println("SIG scores:");
	PrintScores((V:scoreV,CC:scoreCC,D:scoreD,US:scoreUS,UT:scoreUT));
	
	println("\nVolume process time: <createDuration(s1, e1)>");
	println("UnitSize process time: <createDuration(s2, e2)>");
	println("UnitComplexity process time: <createDuration(s3, e3)>");
}

//Get all documentation for M3, mapped on java file - javadoc? - documentation
private map[str,  map[bool, set[loc]]] ParseDocs(M3 model)
{
	map[str, map[bool, set[loc]]] prjDocs = ();
	
	rel[loc, loc] docs = { <resolveJava(d<0>), d<1>>  | d <- model@documentation };
	for(doc <- model@documentation)
	{	
		bool javadoc = !isCompilationUnit(doc<0>);
		str prj = resolveJava(doc<0>).uri;
		if(prj in prjDocs)
		{
			prjDocs[prj][javadoc] += { doc<1> };
		}
		else
		{
			prjDocs[prj] = (false : {}, true : {});
			prjDocs[prj][javadoc] = { doc<1> };
		}
	}
	
	return prjDocs;
}



/*=========================================*/
/*		 	SIG Risks for Units			   */

private map[Risk, int] RisksForUnitSizes(map[loc, int] unitSizes)
{
	map[Risk, int] risks = (Low():0, Mod():0, High():0, Very():0);
	for(key <- unitSizes)
	{
		int size = unitSizes[key];
		risks[RiskForUnit(size)] += size;
	}	
	return risks;
}

private map[Risk, int] RisksForUnitComplexities(map[loc, int] unitComplexities, map[loc, int] unitSizes)
{
	map[Risk, int] risks = (Low():0, Mod():0, High():0, Very():0);
	for(key <- unitSizes)
	{
		loc method = resolveJava(key);
		risks[RiskForUnit(unitComplexities[method])] += unitSizes[key];
	}	
	return risks;
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



/*=========================================*/
/*		 	SIG Results Output			   */

private void PrintRisks(map[Risk, int] risks)
{
	str headers = "\tLow\tMod\tHigh\tVery High";
	str values = "\t<risks[Low()]>%\t<risks[Mod()]>%\t<risks[High()]>%\t<risks[Very()]>%";
	println("\n<headers>\n<values>\n");
}

private void PrintScores(map[str, Score] scores)
{
	Score An = MergeScores([scores[s] | s <- scores, s in {V,D,US,UT}]);
	Score Ch = MergeScores([scores[s] | s <- scores, s in {CC,D}]);
	Score St = MergeScores([scores[s] | s <- scores, s in {UT}]);
	Score Ts = MergeScores([scores[s] | s <- scores, s in {CC,US,UT}]);
	
	println(InsertTabs(["",V,CC,D,US,UT]));
	println(InsertTabs("" + SelectScores(scores, [V,CC,D,US,UT])));
	println(InsertTabs(["-------------------------------------------------"]));
	println(InsertTabs("Any" + SelectScores(scores, [V,"",D,US,UT]) + ToString(An)));
	println(InsertTabs("Chn" + SelectScores(scores, ["",CC,D,"",""]) + ToString(Ch)));
	println(InsertTabs("Stb" + SelectScores(scores, ["","","","",UT]) + ToString(St)));
	println(InsertTabs("Tst" + SelectScores(scores, ["",CC,"",US,UT]) + ToString(Ts)));
}

private list[str] SelectScores(map[str, Score] scores, list[str] selection)
{
	return
		for(s <- selection)
		{
			if(s == "")
				append s;
			else
				append ToString(scores[s]);
		}
}

private str InsertTabs(list[str] strings)
{
	str result = "";
	for(s <- strings)
	{	
		result += "\t| <s>";
	}
	return result;
}