module SigModel

import SigScores;
import volume::LinesOfCode;

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

public void ComputeMetrics(loc project)
{
	println("started building M3 model...");
	M3 model = createM3FromEclipseProject(project);
	println("M3 model built! \n");	
	
	println("started gathering docs...");
	map[str, set[loc]] docs = ParseDocs(model);
	println("docs gathered! \n");
	
	//datetime s1 = now();
	int volume = 24221;
	//Volume(model, docs);
	//datetime e1 = now()
	
	println("started computing unit sizes...");
	datetime s2 = now();
	map[loc, int] unitSizes = ComputeUnitSizes(model, docs);
	map[Risk, int] unitSizeRisks = ComputeUnitRisks(unitSizes, volume);
	datetime e2 = now();
	
	str risks = "";
	str perc = "";
	for(key <- unitSizeRisks)
	{
		risks += "\t<key>";
		perc += "\t<unitSizeRisks[key]>%";
	}
	println("\n<risks>\n<perc>\n");
	
	Score scoreV = N(); // GetVolumeScore(volume);
	Score scoreCC = N();
	Score scoreD = N();
	Score scoreUS = GetUnitScore(unitSizeRisks);
	Score scoreUT = N();
	
	PrintResults(("V":scoreV,"CC":scoreCC,"D":scoreD,"US":scoreUS,"UT":scoreUT));
	
	//println("Volume process time: <createDuration(s1, e1)> \n");
	//println("UnitSize process time: <createDuration(s2, e2)> \n");
}

private map[str, set[loc]] ParseDocs(M3 model)
{
	map[str, set[loc]] prjDocs = ();
	
	rel[loc, loc] docs = { <resolveJava(d<0>), d<1>>  | d <- model@documentation };
	for(doc <- docs)
	{	
		str prj = doc<0>.uri;
		if(prj in prjDocs)
		{
			prjDocs[prj] += { doc<1> };
		}
		else
		{
			prjDocs += (prj : { doc<1> });
		}
	}
	
	return prjDocs;
}

//usable for unitsize/complexity
private map[Risk, int] ComputeUnitRisks(map[loc, int] unitSizes, int volume)
{
	map[Risk, int] risks = (Low():0, Mod():0, High():0, Very():0);
	for(key <- unitSizes)
	{
		int size = unitSizes[key];
		risks[RiskForUnit(size)] += size;
	}	
	
	map[Risk, int] relativeRisks = (Low():0, Mod():0, High():0, Very():0);
	for(r <- risks)
	{
		relativeRisks[r] += round(toReal(risks[r])/toReal(volume)*100);
	}
	
	return relativeRisks;
}


private void PrintResults(map[str, Score] scores)
{
	str V = "V";
	str CC = "CC";
	str D = "D";
	str US = "US";
	str UT = "UT";

	Score An = MergeScores([scores[s] | s <- scores, s in {"V","D","US","UT"}]);
	Score Ch = MergeScores([scores[s] | s <- scores, s in {"CC","D"}]);
	Score St = MergeScores([scores[s] | s <- scores, s in {"UT"}]);
	Score Ts = MergeScores([scores[s] | s <- scores, s in {"CC","US","UT"}]);
	
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