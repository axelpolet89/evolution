module complexity::Cyclomatic

import lang::java::jdt::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import IO;
import List;
import ListRelation;
import Prelude;

import lang::java::m3::Registry;

private loc locationProject = |project://example-project|;
private loc locationSmallSQL = |project://smallsql0.21_src|;


public void createAST()
{
	println("getting ast");
	myAST = createAstsFromEclipseProject(locationSmallSQL, true);
	println("got ast");
	
	println("starting complexity");
	getMethods(myAST);
	//getClasses(myAST);		
}

public void getMethods(set[Declaration] delc)
{			
	int counter = 0;
	
	int counterLow = 0;
	int counterModerate = 0;
	int counterHigh = 0;
	int counterVeryhigh = 0;
	
	map[loc,int] mapie = getMethodsAST(delc);
			
	for(k <- mapie)
	{
		counter += 1;
		str complexity = checkComplexityLevel(mapie[k]);
		println("Location  number <counter> ---- location <k> Value <complexity>");
		if(complexity == "low")
		{
			counterLow += 1;
		}
		else if(complexity == "moderate")
		{
			counterModerate += 1;
		}
		else if(complexity == "high")
		{
			counterHigh += 1;
		}
		else
		{
			counterVeryhigh += 1;
		}
		
	}
	println("amount of methods <counter>");
	println("amount of lows <counterLow>");
	println("amount of moderate <counterModerate>");
	println("amount of high <counterHigh>");
	println("amount of veryhigh <counterVeryhigh>");
	
}

public map[loc,int] ComputeUnitComplexities(loc project)
{
	set[Declaration] delc = createAstsFromEclipseProject(project, true);

	map[loc,int] methodsC = ();
	visit(delc)
	{
	case m : \method(_,_,_,_, Statement impl):
		{
			methodsC += (m@src : countDecisionPoints(impl));
		}
	case mm : \method(_,_,_,_):
		{
			methodsC += (mm@src : 1);
		}
	case c : \constructor(_,_,_, Statement impl):
		{
			methodsC += (c@src : countDecisionPoints(impl));
		}
	}
	return methodsC;
}

public int countDecisionPoints(Statement stat)
{
n = 1;
visit(stat) {
	case \if(_,_):
		n += 1;
	case \if(_,_,_):
		n += 1;		
	case \for(_,_,_,_):
		n += 1;
	case \for(_,_,_):
		n += 1;
	case \foreach(_,_,_):
		n += 1;
	case \while(_,_):
		n += 1;
	case \switch(_,_):
		n += 1;
	case \case(_):
		n += 1;
	case \defaultCase():
		n += 1;
	case \catch(_,_):
		n += 1;	
	case \do(_,_):
		n += 1;
	case \try(_,_):
		n += 1;
	case \try(_,_,_):
		n += 1;
}
return n;
}

public str checkComplexityLevel(int amount)
{
if(amount >= 1 && amount <= 10)
{
	return "low";
}
else if(amount >= 11 && amount <= 20)
{
	return "moderate";
}
else if(amount >= 21 && amount <= 50)
{
	return "high";
}
else
{
	return "very high";
}
}

//Classes not used
public void getClasses(set[Declaration] delc)
{
	int counter = 0;
	set[list[Declaration]] setje = getClassesAST(delc);
	for(k <- setje)
	{
		counter += 1;
		println("location number <counter> --- location <k>");
	}	
	println("amount of classes <counter>");
}

public set[list[Declaration]] getClassesAST(set[Declaration] delc)
{
	set[list[Declaration]] abc = {};
	visit(delc)
	{
		case c : \class(_,_,_, list[Declaration] delc):
		{
			abc += delc;
		}
		case cc : \class(list[Declaration] delc):
		{
			abc += delc;
		}
	}
	return abc;
}
