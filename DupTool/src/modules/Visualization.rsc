module modules::Visualization

import IO;
import String;
import Set;
import List;
import Relation;
import Map;
import util::Math;
import lang::java::jdt::m3::Core;

import vis::Figure;
import vis::Render;
import vis::KeySym;
import util::Editors;
import FProperty;

import modules::CloneDetector;
import helpers::Location;
import helpers::m3;

//data types
data PROJECT = project(loc name, list[CLASS] classes);
data CLASS = class(loc name, list[CLONE] clones);
data CLONE = clone(loc name, list[str] block, list[cloc] cloneClass, int typeClone);

//default margins
private list[FProperty] fplist = [std(gap(17)),shrink(0.5),left()];

//which classes were selected by the user?
private set[CLASS] cSet = {};

//mappings used for indicating internal, external or part-of clones
private map[int,int] typeColor1 = (1:7,2:4,3:9);
private map[int,str] typeColor2 = (1:"Salmon",2:"Lime",3:"Teal");

//these are used for filtering
private list[str] choices;
private int selectedSize = 20;
private int minSize = -1;
private int maxSize = -1;

//most clones in a compilation unit
private int mostClonesInCls = 2;

//stores clone which is clicked upon for details
private CLONE clickedClone;


/*==================================================================
	Initial Render Method
==================================================================*/

public void RenderClones(M3 model, loc prj, cclasses clones)
{	
	set[loc] mdlClasses = {cl | c <- classes(model), cl := FastResolveJava(model, c)}; 
	
	//ccs parsed to per-compilation-unit data
	map[loc, CLASS] cusToRender = ();
	
	//types for clone-class (selecting colors)
	map[list[cloc],int] types = ();
	
	//loop through ccs
	for(key <- clones)
	{
		cc = clones[key];
		
		//determine clone 'type' (internal, external, part-of)
		types[cc] = 1;
		bool internal = false;
		for(c <- cc)
		{
			//internal clone
			if(internal)
			{
				types[cc] = 2;
				break;
			}
		
			if(size({cs | cs <- cc, c[0].uri != cs[0].uri}) == 0)
				internal = true;
		}			
		
		//transform given clone-class into per-compilation-unit clones
		for(c <- cc)
		{
			setClone = {class | class <- mdlClasses, c[0].uri == class.uri};
			if(size(setClone) > 0)
			{
				loc cl = min(setClone);
				if(cl in cusToRender)
				{
					CLASS cur = cusToRender[cl];
					cusToRender[cl] = class(cur.name, cur.clones + clone(c[0],key, cc-c,types[cc]));
				}
				else
				{
					cusToRender[cl] = class(cl, [clone(c[0],key,cc-c,types[cc])]);
				}
			}
		}
	}
	
	//sort classes-to-render by descending, classes with most clones first
	//also sort clones-to-render per class-to-render by descending
	list[CLASS] clsToRender = []; 
	for(c <- sort(range(cusToRender), bool(CLASS a, CLASS b) {return size(a.clones) > size(b.clones);}))
		clsToRender += sortClonesDesc(c); 
	
	//determine min, max and range of filter options
	mostClonesInCls = size(head(clsToRender).clones);
	maxSize = roundDown(mostClonesInCls);
	minSize = roundDown(size(last(clsToRender).clones));
	
	if(minSize == 0)
		minSize = 1;
	if(maxSize == 0)
		maxSize = 1;
		
	if(minSize == maxSize)
	{
		choices = [toString(minSize)];
		selectedSize = maxSize;
	}
	else
	{
		choices = [toString(maxSize-5), toString(minSize)];
		int i = 5;
		while(i < maxSize-5)
		{
			choices += toString(i);
			i += 5;
		}
		
		selectedSize = maxSize;
	}
	
	//render
	render(computeFigure(bool() { return true;}, Figure() {return drawProject(project(prj,clsToRender),false);} ,fplist));
}

private CLASS sortClonesDesc(CLASS cl) = class(cl.name, 
												sort(cl.clones, bool(CLONE a, CLONE b){return (a.name.end.line - a.name.begin.line) 
																									> (b.name.end.line - b.name.begin.line);}));
private int roundDown(int n) = round(n/5)*5;


/*==================================================================
	Draw Project-level node
==================================================================*/

private Figure drawProject(PROJECT pj, bool cloneDetail)
{
	if(cloneDetail == false)
	{
  		x = vcat([
  		text("Select minimum amount of\nclones to show (largest\nby default)"),
  		choice(choices, 
  		void(str s)
  		{ 
  	  		//Remove it from current index
  			int i = indexOf(choices,s);
  			choices = delete(choices,i);  
  				
  			//Sort list without selected value and add selected value at the top
  			choices = sort(choices, bool(str a, str b){ return toInt(a) < toInt(b); });
  			choices = push(s,choices);  
  		
  			//Set global variable for the classes shown with at-least amount of clones "S"
  			selectedSize = toInt(s);
  		},size(50,20*size(choices))
  		)],resizable(false),top());
  	
		b = box(
				tree(
					text(pj.name.uri, size(200,10),fontColor("Red")),	
					selectClasses(pj))
				,size(100,100), align(0,0), fillColor("AliceBlue"));
		return hcat([x,b],top(),left());
	}
	else
	{
		bool hover = false;	
		return box(text(cloneToText(clickedClone),fontSize(9), fontColor("Black")),
		fillColor(Color () { return hover ? color("Coral") : color("AliceBlue"); }),
		lineColor(Color () { return hover ? color("Red") : color("Black"); }),
		onMouseEnter(void () {hover = true;}), onMouseExit(void () {hover= false;}), 
		onMouseDown (bool (int butnr, map[KeyModifier,bool] modifiers) { 		
			render(computeFigure(bool() { return true;}, Figure() {return drawProject(pj,false);} , fplist)); })
		,top(),left());
	}
}



/*==================================================================
	Classes/compilation-units
==================================================================*/

private list[Figure] selectClasses(PROJECT p)
{
	list[Figure] classFigures = [];
		for(c <- [c | c <- p.classes, size(c.clones) >= selectedSize])
			classFigures += drawClass(c,p,c in cSet);
	return classFigures;
}



/*==================================================================
	Class/compilation-unit
==================================================================*/

private Figure drawClass(CLASS c, PROJECT pj, bool detail)
{	
	list[Figure] fg = [];
	 
	if(detail) fg = drawClones(pj,c);
		
	return tree(drawClassContents(c),fg,
					onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { 		
							if(c in cSet)
								cSet -= c;
							else
								cSet += c;
							render(computeFigure(bool() { return true;}, Figure() {return drawProject(pj,false);} , fplist));
							return true;		
		;}));
}

private Figure drawClassContents(CLASS cls)
{
	list[LineDecoration] cloneLines = [];
	
	set[tuple[int,int]] lines = {};
	
	int allCloneLines = 0;
	int allClassLines = cls.name.end.line;
		
	for(c <- cls.clones)
	{
		int b = c.name.begin.line;
		int e = c.name.end.line;
		int cType = c.typeClone;
		
		//intern
		if(size({l | l <- lines, b > l[0] && e < l[1]}) > 0)
		{
			cType = 3;
			c.typeClone = cType;
		}
		
		for(i <- [b..e + 1])
			cloneLines += highlight(i,"",typeColor1[cType]);
			
		lines += <b,e>;
		
		//total clone lines
		allCloneLines += size(c.block);
	}
	
	bool hover = false;	
	int h = (300 * size(cls.clones) / mostClonesInCls);
	int w = (400 * allCloneLines / allClassLines);
	
	return overlay([box(size(w, h + 25)),
					outline(cloneLines, cls.name.end.line, size(w, h), bottom(), 
								fillColor(Color () { return hover ? color("WhiteSmoke") : color("Snow"); }),
								lineColor(Color () { return hover ? color("Red") : color("Black"); }),
								onMouseEnter(void () {hover = true;}), onMouseExit(void () {hover= false;})), 
					text(replaceAll(cls.name.file, "."+cls.name.extension, ""),fontColor("Red"),fontSize(9),size(100,25),top())]);
}



/*==================================================================
	Clones (grid)
==================================================================*/

private list[Figure] drawClones(PROJECT pj,CLASS cls)
{
	int counter = 0;
	list[Figure] row = [];
	list[list[Figure]] figs = [[]];
	
	int maxCloneLines = 0;
	int maxCloneClass = 0;
	for(c <- cls.clones)
	{
		//maxCloneLines metric
		int clines = c.name.end.line - c.name.begin.line;
		if(clines > maxCloneLines)
			maxCloneLines = clines;

		int ccSize = size(c.cloneClass);
		if(ccSize > maxCloneClass)
			maxCloneClass = ccSize;
	}
	
	set[tuple[int,int]] lines = {};
	for(c <- cls.clones)
	{
		counter += 1;
		
		int b = c.name.begin.line;
		int e = c.name.end.line;
		
		//is the clone part-of another clone, then set type to 3
		if(size({l | l <- lines, b > l[0] && e < l[1]}) > 0)
			c.typeClone = 3;
			
		lines += <b,e>;
		
		row += drawClone(pj,c,maxCloneLines,maxCloneClass+1);	
		if(counter == 5)
		{
			figs += [row];
			counter = 0;
			row = [];
		}
	}
	
	if(size(row) < 5)
		figs += [row];

	return [box(grid(figs),fillColor("Snow"))];
}



/*==================================================================
	Clone details
==================================================================*/

private Figure drawClone(PROJECT pj, CLONE c,int maxCloneLines,int maxCloneClass)
{
	h = (100 * size(c.block) / maxCloneLines);
	w = (100 * size(c.cloneClass+1) / maxCloneClass);
	
	bool hover = false;	
	return box(size(w, h), resizable(false),
		fillColor(Color () { return hover ? color("WhiteSmoke") : color(typeColor2[c.typeClone]); }),
		lineColor(Color () { return hover ? color("Red") : color("Black"); }),
		onMouseEnter(void () {hover = true;}), onMouseExit(void () {hover= false;}), 
		onMouseDown (bool (int butnr, map[KeyModifier,bool] modifiers) { 		
			clickedClone = c;
			render(computeFigure(bool() { return true;}, Figure() {return drawProject(pj,true);} , fplist));	
		})
	);
}

private str cloneToText(CLONE cl)
{
	str result = "lines: <cl.name.begin.line> - <cl.name.end.line>";
	result += "\r\n\r\nmatches with:\r\n";
	for(c <- cl.cloneClass)
		result += "<c[0]>\r\n";
	result += "\r\nsource code:\r\n<blockToString(cl.block)>";
	return result;
}

private str blockToString(list[str] block)
{
	str result = "";
	for(l <- block)
		result += "<l>\r\n";
	return result;
}