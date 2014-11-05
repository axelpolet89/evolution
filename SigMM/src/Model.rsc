module Model

import IO;
import List;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import volume::LinesOfCode;

public loc prjDude = |project://Dude|;
public loc prjSS = |project://SmallSql|;
public loc prjHS = |project://hsqldb|;

public void ComputeMetrics(loc project)
{
	M3 model = createM3FromEclipseProject(project);
	println("M3 model built!");	
	
	TotalLOC(model);
	
	//int volume = 0; 
	//println("Lines of Code: <volume>");
}

public void PrintClasses(M3 model, int max)
{
	for(c <- classes(model))
	{
		println(readFile(c));
	}
}