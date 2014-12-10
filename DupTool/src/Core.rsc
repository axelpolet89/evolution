module Core

import IO;
import DateTime;
import Set;
import List;
import Map;
import util::Math;
import lang::java::jdt::m3::Core;

import modules::CodeCleaner;
import modules::CloneDetector;
import modules::Visualization;
import helpers::m3;
import helpers::Location;
import helpers::Percentage;

public loc prjSS = |project://SmallSql|;
public loc prjSS2 = |project://smallsql0.21|;
public loc prjHS = |project://hsqldb|;
public loc prjHS2 = |project://hsqldb-2.3.1|;
public loc prjDE = |project://DuplicationExamples|;

private loc outputFolder = |file:///c:/users/axel/desktop|;

private str ParseDuration(datetime s, datetime e)
{
	d = createDuration(s, e);	
	return "<d[4]> minutes, <d[5]>.<d[6]> seconds";
}

public void InitCDSS(bool saveToFile)
{
	 InitCloneDetection(prjSS, saveToFile);
}

public void InitCDHS(bool saveToFile)
{
	 InitCloneDetection(prjHS, saveToFile);
}

public void InitCDDE(bool saveToFile)
{
	 InitCloneDetection(prjDE, saveToFile);
}


/*==================================================================
	Main Call for Clone Detection
==================================================================*/

public void InitCloneDetection(loc project, bool saveToFile)
{
	list[str] timings = [];

	println("started building M3 model...");
	M3 model = GenerateM3(project);
	println("M3 model built!\n");	
	
	println("started gathering docs...");
	datetime sD = now();
	docs = ParseDocs(model);
	datetime eD = now();
	timings += "--\> Documentation gather time: <ParseDuration(sD, eD)>";
	println("docs gathered!\n");
	
	println("started computing volume...");
	datetime s1 = now();
	compilationUnits = GetModelVolume(model, docs);
	int volume = compilationUnits<0>;		
	datetime e1 = now();
	timings += "--\> Volume process time: <ParseDuration(s1, e1)>";
	println("volume computed!");	
	
	int duplicateLOC = 0;
	println("\nstarted search for clones...");
	datetime s4 = now();
	clones = FindClones(compilationUnits<1>);
	datetime e4 = now();
	timings += "--\> clone search time: <ParseDuration(s4, e4)>";
	println("clone detection completed!");

	println("");
	for(t <- timings)
		println(t);
	
	println("\n");	
	list[str] stats = GetCloneStatistics(project, volume, clones);
	for(s <- stats)
		println(s);	
	
	if(saveToFile)
	{
		loc outputFile = outputFolder + "report_CDtool_<printTime(now(), "yyyyMMdd_HH-mm-ss")>.txt";
		ListToFile(outputFile, stats);
		println("\nStatistics saved in <outputFile>");
	}
	
	println("\nRendering clones...");
	RenderClones(model, project, clones);
}

/*==================================================================
	Compute clone statistics and transform them into 
	representational information
==================================================================*/
private list[str] GetCloneStatistics(loc project, int volume, cclasses clones)
{
	list[str] result = [];
	
	result += "Duplication Statistics for Java project: <project.uri>\r\n";
	result += "Volume:\t\t\t\t<volume> SLOC";
		
	int dupsVol = GetCloneTotal(clones);
	
	result += "Duplicate lines:\t\t<dupsVol> SLOC";
	result += "Percentage of clones:\t\t<GetPercentage(dupsVol, volume)>%\r\n";
	
	result += "Number of clone classes:\t<size(domain(clones))>\r\n";
	
	set[list[str]] blocks = domain(clones);
	int max = 0;
	list[str] bClone = [];
	for(b <- blocks)
	{
		int s = size(b);
		if(s > max)
		{
			max = s;
			bClone = b;
		}
	}
	
	max = 0;
	list[str] bCloneClass= [];
	list[cloc] bClass = [];
	for(key <- clones)
	{
		list[cloc] class = clones[key]; 
		int s = size(class);
		if(s > max)
		{
			max = s;
			bClass = class;
			bClassDup = key;
		}
	}
	
	result += "Biggest clone:\t\t\t<size(bClone)> SLOC\r\n";
	for(i <- [0..size(bClone)])
		result += "\t\t\t\t<bClone[i]>"; 
	
	result += "\r\nBiggest clone class (<size(bClass)>):\t\t";
	for(i <- [0..size(bClass)])		
		result += "\t\t\t\t<bClass[i][0]>  -\> line <bClass[i][0].begin.line> to <bClass[i][0].end.line>";
	result+="";
	for(i <- [0..size(bCloneClass)])
		result += "\t\t\t\t<bCloneClass[i]>"; 
	
	
	return result;
}

/*==================================================================
	Save list of strings (lines) to a file
==================================================================*/
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