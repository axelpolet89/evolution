module SigModel

import Scores;
import Risks;

import computations::LinesOfCode;
import computations::CyclomaticComplexity;
import computations::Duplications;

import lang::java::jdt::m3::Core;
import lang::java::m3::Registry;

import IO;
import DateTime;
import Set;
import Map;
import Relation;
import List;

public loc prjDude = |project://Dude|;
public loc prjDude2 = |project://Dude/src|;
public loc prjSS = |project://SmallSql|;
public loc prjHS = |project://hsqldb|;

//const strings for SIG scores on volume, complexity, duplicates, unit sizes, unit tests
str V = "V";
str CC = "CC";
str D = "D";
str US = "US";
str UT = "UT";

//Get all documentation for M3, mapped on java file - javadoc? - documentation
private map[str,  map[bool, set[loc]]] ParseDocs(M3 model)
{
	println("--\> # of docs in M3: <size(model@documentation)>");
	
	map[str, map[bool, set[loc]]] prjDocs = ();
		
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

private str ParseDuration(datetime s, datetime e)
{
	d = createDuration(s, e);	
	return "<d[4]> minutes, <d[5]>.<d[6]> seconds";
}

public void ComputeDude()
{
	 ComputeMetrics(prjDude, true, false);
}

public void ComputeSS()
{
	 ComputeMetrics(prjSS, true, false);
}

//Main call to compute SIG metrics
public void ComputeMetrics(loc project, bool enableV, bool enableD)
{
	Score scoreV = N();
	Score scoreCC = N(); 
	Score scoreD = N();
	Score scoreUS = N();
	Score scoreUT = N();
	
	list[str] timings = [];

	println("started building M3 model...");
	M3 model = createM3FromEclipseProject(project);
	println("M3 model built!\n");	
	
	println("started gathering docs...");
	datetime sD = now();
	map[str, map[bool, set[loc]]] docs = ParseDocs(model);
	datetime eD = now();
	timings += "--\> Documentation gather time: <ParseDuration(sD, eD)>";
	println("docs gathered!\n");
	
	int volume = 24221;
	if(enableV)
	{
		println("started computing volume...");
		datetime s1 = now();
		tuple[int, map[loc, list[str]]] cuSizes = GetModelVolume(model, docs);
		volume = cuSizes<0>;		
		datetime e1 = now();
		timings += "--\> Volume process time: <ParseDuration(s1, e1)>";
		println("--\> Total LOC : <volume>");
		println("volume computed!");
		
		MatchClasses(cuSizes<1>);
	}

	println("\nstarted computing unit sizes...");
	datetime s2 = now();
	map[loc, int] unitSizes = GetModelUnitSizes(model, docs);
	int locInUnits = 0;
	for(key <- unitSizes) 
		locInUnits += unitSizes[key];
	datetime e2 = now();
	timings += "--\> UnitSize process time: <ParseDuration(s2, e2)>";
	println("--\> Total LOC in units: <locInUnits>");
	println("unit sizes computed!");
	
	
	println("\nstarted computing unit complexities...");
	datetime s3 = now();
	map[loc, int] unitComplexities = GetUnitComplexitiesForProject(project);
	datetime e3 = now();	
	timings += "--\> UnitComplexity process time: <ParseDuration(s3, e3)>";
	println("unit complexities computed!");
	
	int duplications = 0;
	if(enableD)
	{
		println("\nstarted search for duplicates...");
		datetime s4 = now();
		int duplications = FindDuplicates(units);
		datetime e4 = now();
		timings += "--\> Duplication search time: <ParseDuration(s4, e4)>";
		println("completed duplicates search!");
	}
	
	println("\ncomputing scores...");
	
	scoreV = GetVolumeScore(volume);
	
	map[Risk, int] unitSizeRisks = RisksForUnitSizes(unitSizes, locInUnits);
	scoreUS = GetUnitScore(unitSizeRisks);
	
	map[Risk, int] unitComplexityRisks = RisksForUnitComplexities(unitComplexities, unitSizes, locInUnits);
	scoreCC = GetUnitScore(unitComplexityRisks);	
	
	println("\nunit size risks:");
	PrintRisks(unitSizeRisks);
	
	println("\nunit complexity risks:");
	PrintRisks(unitComplexityRisks);
	
	println("\nSIG scores:");
	PrintScores((V:scoreV,CC:scoreCC,D:scoreD,US:scoreUS,UT:scoreUT));
		
	println("\n");
	for(t <- timings)
		println(t);
}




/*=========================================*/
/*		 	OUTPUT						   */

private void PrintRisks(map[Risk, int] risks)
{
	str headers = "\tLow\tMod\tHigh\tVery High";
	str values = "\t<risks[Low()]>%\t<risks[Mod()]>%\t<risks[High()]>%\t<risks[Very()]>%";
	println("<headers>\n<values>");
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