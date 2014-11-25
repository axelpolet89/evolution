module computations::CyclomaticComplexity

import lang::java::jdt::m3::AST;

public map[loc,int] GetUnitComplexitiesForProject(loc project)
{
	map[loc,int] methodsC = ();
	
	visit(createAstsFromEclipseProject(project, true))
	{
		case m : \method(_,_,_,_, Statement impl):
			{
				methodsC += (m@src : CountComplexity(impl));
			}
		case mm : \method(_,_,_,_):
			{
				methodsC += (mm@src : 1);
			}
		case c : \constructor(_,_,_, Statement impl):
			{
				methodsC += (c@src : CountComplexity(impl));
			}
	}
	
	return methodsC;
}

public int CountComplexity(Statement stat)
{
	n = 1;
	visit(stat) {
		case \if(Expression condition,_):
		{
			n += 1;
			n += checkIfStatement(condition);
		}
		case \if(Expression condition,_,_):
		{
			n += 1;		
			n += checkIfStatement(condition);
		}
			
		case \for(_,_,_,_):
			n += 1;
		case \for(_,_,_):
			n += 1;
		case \foreach(_,_,_):
			n += 1;
			
		case \do(_,_):
			n += 1;
		case \while(_,_):
			n += 1;
		//case \switch(_,_):
			//n += 1;
		case \case(_):
			n += 1;
		//case \defaultCase():
			//n += 1;
			
		//case \try(_,_):
			//n += 1;
		case \try(_,_,_):
			n += 1;
		case \catch(_,_):
			n += 1;	
	}
	
	return n;
}

private int checkIfStatement(Expression condition)
{
	int n = 0;
	for(c <- condition)
	{
		if(c == "&&" || c == "||")
		{
			n += 1;
		}
	}
	return n;
}