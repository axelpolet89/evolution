module modules::Visualization

import modules::CloneDetector;
import helpers::Location;
import helpers::m3;

import vis::Figure;
import vis::Render;
import vis::KeySym;
import util::Editors;
import FProperty;

import IO;
import String;
import List;
import Set;
import Map;
import Relation;
import lang::java::jdt::m3::Core;
import util::Math;

public loc prjexample = |project://example-project|;
public loc smallSQL = |project://smallsql0.21_src|;

public list[FProperty] fplist = [std(gap(20)),shrink(0.5),left()];

data PROJECT = project(loc name, list[CLASS] classes);
data CLASS = class(loc name, list[CLONE] clones);
data CLONE = clone(loc name, str block, list[cloc] cloneClass);

//which classes were selected by the user?
public set[CLASS] cSet = {};

//these are used for filtering
public int selectedSize = -1;
public int minSize = -1;
public int maxSize = -1;

//Creates data objects from M3 model
public void RenderClones(M3 model, loc prj, map[list[str], list[cloc]] clones)
{	
	set[loc] mdlClasses = {cl | c <- classes(model), cl := FastResolveJava(model, c)}; 
	map[loc, CLASS] renderClasses = ();
	for(key <- clones)
	{
		cc = clones[key];
		for(c <- cc)
		{
			loc cl = min({class | class <- mdlClasses, c[0].uri == class.uri});
			if(cl in renderClasses)
			{
				CLASS cur = renderClasses[cl];
				renderClasses[cl] = class(cur.name, cur.clones + clone(c[0],blockToString(key), cc-c));
			}
			else
			{
				renderClasses[cl] = class(cl, [clone(c[0],blockToString(key),cc-c)]);
			}
		}
	}
	
	//sort render-classes by descending, classes with most clones first
	list[CLASS] classClones = []; 
	for(c <- sort(range(renderClasses), bool(CLASS a, CLASS b) {return size(a.clones) > size(b.clones);}))
		classClones += sortClonesDesc(c); 
		
	maxSize = size(head(classClones).clones);
	minSize = size(last(classClones).clones);
	
	render(computeFigure(bool() { return true;}, Figure() {return drawProject(project(prj,classClones));} ,fplist));
}

private CLASS sortClonesDesc(CLASS cl)
{
	return class(cl.name, sort(cl.clones, bool(CLONE a, CLONE b){return (a.name.end.line - a.name.begin.line) > (b.name.end.line - b.name.begin.line);}));
}

private str blockToString(list[str] block)
{
	str result = "";
	for(l <- block)
		result += "<l>\r\n";
	return result;
}

private Figure drawProject(PROJECT p)
{
	return box(
			tree(
				text(p.name.uri, size(200,10),fontColor("RED")),	
				selectClasses(p))
			,size(100,100), align(0,0));
}

private list[Figure] selectClasses(PROJECT p)
{
	list[Figure] classFigures = [];
	if(selectedSize != -1)
		for(c <- [c | c <- p.classes, size(c.clones) == selectedSize])
			classFigures += drawClass(c,p,c in cSet);
	else
		for(c <- p.classes)
			classFigures += drawClass(c,p,c in cSet);
	return classFigures;
}

private Figure drawClass(CLASS c, PROJECT pj, bool detail)
{	
	list[Figure] fg = [];
	total = toInt(sum([s | cl <- c.clones, s := (cl.name.end.line - cl.name.begin.line)])); 
	if(detail) fg = [drawClone(cl, total) | cl <- c.clones];
		
	return tree(drawClassContents(c),fg,
	onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { 		
			if(c in cSet)
				cSet -= c;
			else
				cSet += c;
			render(computeFigure(bool() { return true;}, Figure() {return drawProject(pj);} , fplist));
			return true;		
		;}));
}

private Figure drawClassContents(CLASS c)
{
	list[LineDecoration] cloneLines = [];
	
	set[tuple[int,int]] lines = {};
		
	for(cl <- c.clones)
	{
		int b = cl.name.begin.line;
		int e = cl.name.end.line;
		int color = 7;
		
		if(size({cs | cs <- cl.cloneClass, c.name.uri != cs[0].uri}) == 0)
			color = 2;
		else if(size({l | l <- lines, b > l[0] && e < l[1]}) > 0)
			color = 9;
		
		for(i <- [b..e + 1])
			cloneLines += highlight(i,"",color);
		lines += <b,e>;
	}

	bool hover = false;	
	return overlay([box(size(100, c.name.end.line + 20)),
					outline(cloneLines, c.name.end.line, size(100, c.name.end.line), bottom(), 
								fillColor(Color () { return hover ? color("PowderBlue") : color("WhiteSmoke"); }),
								onMouseEnter(void () {hover = true;}), onMouseExit(void () {hover= false;})), 
					text(replaceAll(c.name.file, "."+c.name.extension, ""),fontColor("Black"),fontSize(8),size(100,20),top())]);
}


private Figure drawClone(CLONE cl, int total)
{
	cln = cl.name;
	perc = 100 * (cln.end.line - cln.begin.line) / total;
	
	bool hover = false;	
	return box(text(cloneToText(cl), fontSize(8), fontColor("White")), 
		size(20, 2*perc),
		fillColor(Color () { return hover ? color("OrangeRed") : color("Sienna"); }),
		onMouseEnter(void () {hover = true;}), onMouseExit(void () {hover= false;}), 
		onMouseDown (bool (int butnr, map[KeyModifier,bool] modifiers) { 		
			edit(cl.name);	
		})
	);
}

private str cloneToText(CLONE cl)
{
	str result = "lines: <cl.name.begin.line> - <cl.name.end.line>\r\n\r\nmatches with:\r\n";
	for(c <- cl.cloneClass)
		result += "<c[0]>\r\n";
	result += "\r\nsource code:\r\n<cl.block>";
	return result;
}

public Figure hBarChart(map[int,str] vals)
{	
	//List met class + amount of clones
	

	list[Figure] listf = [box(text(vals[k]),size(100,10*k),fillColor("blue"),resizable(false))| k <- vals];
	return hcat(listf,std(bottom()));
}