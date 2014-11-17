module SigModel

import Scores;
import Risks;

import volume::LinesOfCode;
import complexity::Cyclomatic;
import duplication::Simple;

import lang::java::jdt::m3::Core;
import lang::java::m3::Registry;

import IO;
import DateTime;
import Set;
import Map;
import Relation;
import List;

public loc prjDude = |project://Dude|;
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

private str ParseDuration(datetime s, datetime e)
{
	d = createDuration(s, e);	
	return "<d[4]> minutes, <d[5]>.<d[6]> seconds";
}

//Main call to compute SIG metrics
public void ComputeMetrics(loc project)
{
	println("started building M3 model...");
	M3 model = createM3FromEclipseProject(project);
	println("M3 model built!\n");	
	
	println("started gathering docs...");
	datetime sD = now();
	map[str, map[bool, set[loc]]] docs = ParseDocs(model);
	datetime eD = now();
	println("docs gathered!\n");
	
	println("started computing volume...");
	datetime s1 = now();
	int volume = 24221;//Volume(model, docs);
	datetime e1 = now();
	println("volume computed!\n");
	
	println("started computing unit sizes...");
	datetime s2 = now();
	//map[loc, int] unitSizes = ComputeUnitSizes(model, docs);
	map[loc, list[str]] units = ComputeUnitSizesEx(model, docs);
	map[loc, int] unitSizes = ();
	for(key <- units)
		unitSizes[key] = size(units[key]);
	datetime e2 = now();
	println("unit sizes computed!\n");
	
	println("started search for duplicates...");
	datetime s4 = now();
	int duplications = FindDuplicates(units);
	datetime e4 = now();
	println("completed duplicates search!\n");
	println("duplicate code: <duplications>\n");
	
	println("started computing unit complexities...");
	datetime s3 = now();
	map[loc, int] unitComplexities = ComputeUnitComplexities(project);		
	datetime e3 = now();	
	println("unit complexities computed!\n");
	
	int unitsLOC = 0;
	for(key <- unitSizes)
		unitsLOC += unitSizes[key];
	
	map[Risk, int] unitSizeRisks = RisksForUnitSizes(unitSizes, unitsLOC);
	map[Risk, int] unitComplexityRisks = RisksForUnitComplexities(unitComplexities, unitSizes, unitsLOC);
	
	println("Unit size risks:");
	PrintRisks(unitSizeRisks);
	println("Unit complexity risks:");
	PrintRisks(unitComplexityRisks);
	
	Score scoreV = GetVolumeScore(volume);
	Score scoreCC = GetUnitScore(unitComplexityRisks);
	Score scoreD = N();
	Score scoreUS = GetUnitScore(unitSizeRisks);
	Score scoreUT = N();
	
	println("\n--\> Documentation gather time: <ParseDuration(sD, eD)>");
	println("--\> Volume process time: <ParseDuration(s1, e1)>");
	println("--\> UnitSize process time: <ParseDuration(s2, e2)>");
	println("--\> UnitComplexity process time: <ParseDuration(s3, e3)>");
	println("\n--\>SIG scores:");
	PrintScores((V:scoreV,CC:scoreCC,D:scoreD,US:scoreUS,UT:scoreUT));
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