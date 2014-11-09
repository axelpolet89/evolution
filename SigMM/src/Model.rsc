module Model

import IO;
import lang::java::jdt::m3::Core;
import volume::LinesOfCode;

public loc prjDude = |project://Dude|;
public loc prjSS = |project://SmallSql|;
public loc prjHS = |project://hsqldb|;

public void ComputeMetrics(loc project)
{
	M3 model = createM3FromEclipseProject(project);
	println("M3 model built!");	
	
	Volume(model);
	UnitSize(model);
}