module Core

import libs::CodeCleaner;
import libs::DuplicationSearch;

import lang::java::jdt::m3::Core;
import lang::java::m3::Registry;
import util::Math;

import IO;
import DateTime;
import Set;
import Map;
import Relation;
import List;

public loc prjDude = |project://Dude|;
public loc prjDude2 = |project://Dude/src|;
public loc prjSS = |project://SmallSql|;
public loc prjSS2 = |project://smallsql0.21|;
public loc prjHS = |project://hsqldb-2.3.1|;

//Get all documentation for M3, mapped on java file - javadoc? - documentation
private map[str,  set[loc]] ParseDocs(M3 model)
{
	println("--\> # of docs in M3: <size(model@documentation)>");
	
	map[str, set[loc]] prjDocs = ();
	
	println("--\> started mapping docs on compilation-unit uri...");	
	for(doc <- model@documentation)
	{	
		str prj = resolveJava(doc<0>).uri;
		if(prj in prjDocs)
		{
			prjDocs[prj] += { doc<1> };
		}
		else
		{
			prjDocs[prj] = { doc<1> };
		}
	}
	println("--\> mapped documentation on <size(domain(prjDocs))> compilation-units!");
	
	return prjDocs;
}

private str ParseDuration(datetime s, datetime e)
{
	d = createDuration(s, e);	
	return "<d[4]> minutes, <d[5]>.<d[6]> seconds";
}

private int GetPercentage(int num1, int num2) = round(toReal(num1)/toReal(num2)*100);

public void ComputeDude()
{
	 ComputeMetrics(prjDude);
}

public void ComputeSS()
{
	 ComputeMetrics(prjSS);
}

public void ComputeHS()
{
	 ComputeMetrics(prjHS);
}

//Main call to compute SIG metrics
public void ComputeMetrics(loc project)
{
	list[str] timings = [];

	println("started building M3 model...");
	M3 model = createM3FromEclipseProject(project);
	println("M3 model built!\n");	
	
	println("started gathering docs...");
	datetime sD = now();
	map[str, set[loc]] docs = ParseDocs(model);
	datetime eD = now();
	timings += "--\> Documentation gather time: <ParseDuration(sD, eD)>";
	println("docs gathered!\n");
	
	println("started computing volume...");
	datetime s1 = now();
	tuple[int, map[loc, list[str]]] compilationUnits = GetModelVolume(model, docs);
	int volume = compilationUnits<0>;		
	datetime e1 = now();
	timings += "--\> Volume process time: <ParseDuration(s1, e1)>";
	println("volume computed!");	
	
	int duplicateLOC = 0;
	println("\nstarted search for duplicates...");
	datetime s4 = now();
	duplicateLOC = CountDuplicateLines(compilationUnits<1>);
	datetime e4 = now();
	timings += "--\> Duplication search time: <ParseDuration(s4, e4)>";
	println("completed duplicates search!");
	
	println("\n--\> Total LOC : <volume>");
	println("--\> Total LOC in duplicates: <duplicateLOC>");
	println("\nduplication percentage: <GetPercentage(duplicateLOC, volume)>%");
			
	println("\n");
	for(t <- timings)
		println(t);
}