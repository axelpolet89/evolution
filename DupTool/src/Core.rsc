module Core

import libs::CodeCleaner;
import libs::DuplicationSearch;
import libs::LocationHelpers;

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
public loc prjHS = |project://hsqldb|;
public loc prjHS2 = |project://hsqldb-2.3.1|;
public loc prjDE = |project://DuplicationExamples|;

alias lline = tuple[str,int,int];

private loc outputFolder = |file:///c:/users/axel/desktop|;

//Get all documentation for M3, mapped on java file - javadoc? - documentation
private map[str,  set[loc]] ParseDocs(M3 model)
{
	map[str, set[loc]] docs = ();
	
	int total = size(model@documentation);
	println("--\> # of docs in M3: <total>");
	println("--\> started mapping docs on compilation-unit uri...");	
	
	int count = 0;
	for(doc <- model@documentation)
	{	
		str cUri;
		loc d = doc[0];
		if (<d, src> <- model@declarations)
    		cUri = src.uri;
      
		if(cUri in docs)
			docs[cUri] += { doc[1] };
		else
			docs[cUri] = { doc[1] };	
		
		count +=1;
		
		if(count % 100 == 0)
			println("--\> mapped <count> of <total> docs so far.."); 
	}
	
	println("--\> mapped documentation on <size(docs)> compilation-units!");
	return docs;
}

private str ParseDuration(datetime s, datetime e)
{
	d = createDuration(s, e);	
	return "<d[4]> minutes, <d[5]>.<d[6]> seconds";
}

private real GetPercentage(int num1, int num2) = round(toReal(num1)/toReal(num2)*100,0.11);

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

public void ComputeDE()
{
	ComputeMetrics(prjDE);
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
	tuple[int, map[loc, list[lline]]] compilationUnits = GetModelVolume(model, docs);
	int volume = compilationUnits<0>;		
	datetime e1 = now();
	timings += "--\> Volume process time: <ParseDuration(s1, e1)>";
	println("volume computed!");	
	
	int duplicateLOC = 0;
	println("\nstarted search for duplicates...");
	datetime s4 = now();
	//duplicateLOC = CountDuplicateLines(compilationUnits<1>);
	duplications = FindDuplicates(compilationUnits<1>);
	datetime e4 = now();
	timings += "--\> Duplication search time: <ParseDuration(s4, e4)>";
	println("completed duplicates search!");
	
	//println("\n--\> Total LOC : <volume>");
	//println("--\> Total LOC in duplicates: <duplicateLOC>");
	//println("\nduplication percentage: <GetPercentage(duplicateLOC, volume)>%");
	println("");
	for(t <- timings)
		println(t);
	
	println("\n");	
	list[str] stats = GetDuplicationStatistics(project, volume, duplications);
	for(s <- stats)
		println(s);	
	
	loc outputFile = outputFolder + "report_duptool_<printTime(now(), "yyyyMMdd_HH-mm-ss")>.txt";
	//ListToFile(outputFile, stats);
	println("\nStatistics saved in <outputFile>");
}


private list[str] GetDuplicationStatistics(loc project, int volume, map[list[str], list[duploc]] duplications)
{
	list[str] result = [];
	
	result += "Duplication Statistics for Java project: <project.uri>\r\n";
	result += "Volume:\t\t\t\t<volume> SLOC";
		
	int dupsVol = GetCloneTotal(duplications);
	
	result += "Duplicate lines:\t\t<dupsVol> SLOC";
	result += "Percentage of clones:\t\t<GetPercentage(dupsVol, volume)>%\r\n";
	
	result += "Total # of clone classes:\t<size(domain(duplications))>\r\n";
	
	set[list[str]] dups = domain(duplications);
	int max = 0;
	list[str] bDup = [];
	for(d <- dups)
	{
		int s = size(d);
		if(s > max)
		{
			max = s;
			bDup = d;
		}
	}
	
	max = 0;
	list[str] bClassDup = [];
	list[duploc] bClass = [];
	for(key <- duplications)
	{
		list[duploc] class = duplications[key]; 
		int s = size(class);
		if(s > max)
		{
			max = s;
			bClass = class;
			bClassDup = key;
		}
	}
	
	result += "Biggest clone:\t\t\t<size(bDup)> SLOC\r\n";
	for(i <- [0..size(bDup)])
		result += "\t\t\t\t<bDup[i]>"; 
	
	result += "\r\nBiggest clone class:\t\t<bClass[0][0]> -\> line <bClass[0][0].begin.line> to <bClass[0][0].end.line>";
	for(i <- [1..size(bClass)])		
		result += "\t\t\t\t<bClass[i][0]>  -\> line <bClass[i][0].begin.line> to <bClass[i][0].end.line>";
	result+="";
	for(i <- [0..size(bClassDup)])
		result += "\t\t\t\t<bClassDup[i]>"; 
	
	
	return result;
}

private void ListToFile(loc file, list[str] lines)
{	
	if(!isFile(file))
		writeFile(file);
	
	for(s <- lines)
	{
		appendToFile(file, s);
		appendToFile(file, "\r\n");
	}
}