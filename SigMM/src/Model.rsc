module Model

import IO;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import volume::LinesOfCode;

public loc prjDude = |project://Dude|;

public void ComputeMetrics(loc project)
{
	M3 model = createM3FromEclipseProject(project);
	
	int volume = TotalLOC(model);
	
	println("Lines of Code: <volume>");
}