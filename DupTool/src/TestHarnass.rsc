module TestHarnass

import modules::CodeCleaner;
import modules::CloneDetector;
import helpers::m3;
import helpers::Location;
import helpers::String;

import IO;
import Set;
import Map;
import List;
import util::Math;
import lang::java::jdt::m3::Core;
import lang::java::m3::Registry;

private loc th = |project://DuplicationExamples|;
private bool passed = true;
alias utr = tuple[bool,str];

private tuple[int, map[loc,list[lline]]] GetSourceForTest()
{
	M3 model = GenerateM3(th);
		
	docs = ParseDocs(model);
	println("docs gathered!\n");
	
	compilationUnits = GetModelVolume(model, docs);
	println("volume computed!\n");
	
	return compilationUnits;
}

/* 
	Unit tests: do individual units of computation work as expected?
*/

public void StartUnitTests()
{
	println("unit-tests started!");
	list[utr] results = [];
	
	results += TstModifyLocation();
	results += TstGetLineDescriptors();
	results += TstIsInRange();
	results += TstLocSelectors();

	M3 model = GenerateM3(th);
	results += TstFastResolveJava(model);
	
	results += TstFilterStrSection();
	
	results += TstCloneSortFilter(GetSourceForTest());
	
	list[utr] faults = [r | r <- results, r[0] == false];
	if(size(faults) > 0)
	{
		println("unit-tests failed!\n");
		for(f <- faults)
			println(f[1]);
		println("\nunit-tests failed!");	
		return;
	}
	
	println("unit-tests succeeded!");
}

//helpers::Location
private utr TstModifyLocation()
{
	loc exp =  |project://test/src/main,java|(50,20,<5,0>,<6,0>);
	loc res = ModifyLocation(|project://test/src/main,java|(0,100,<0,0>,<10,0>), 50,20,5,6);
	
	if(exp != res)
		return <false,"at helpers::Location::ModifyLocation()\r\nexp:<exp>\r\nres:<res>">;
		
	return <true,"">;
}

private utr TstGetLineDescriptors()
{
	lines = ["first","second","third"];
	list[lline] exp = [<"first",1,0>,<"second",2,7>,<"third",3,15>];
	list[lline] res = GetLineDescriptors(lines);
	
	if(exp != res)
		return <false,"at helpers::Location::GetLineDescriptors()\r\nlines:<lines>\r\n<exp>\r\n<res>">;
				
	return <true,"">;
}

private utr TstIsInRange()
{
	loc l1 = |project://test/src/main,java|(50,20,<5,0>,<10,0>);
	loc l2 = |project://test/src/main,java|(60,5,<7,0>,<8,0>);
	
	if(!IsInRange(l1,l2))
		return <false, "at helpers::Location::IsInRange():Should be in range!\r\nrange:<l1>\r\ntarget:<l2>">;
		
	l2 = |project://test/src/main,java|(60,5,<3,0>,<8,0>);
	
	if(!IsInRange(l1,l2))
		return <false, "at helpers::Location::IsInRange():Should be in range!\r\nrange:<l1>\r\ntarget:<l2>">;
		
	l2 = |project://test/src/main,java|(60,5,<6,0>,<11,0>);
	
	if(!IsInRange(l1,l2))
		return <false, "at helpers::Location::IsInRange():Should be in range!\r\nrange:<l1>\r\ntarget:<l2>">;
		
	l2 = |project://test/src/main,java|(60,5,<3,0>,<4,0>);
	
	if(IsInRange(l1,l2))
		return <false, "at helpers::Location::IsInRange():Should NOT be in range!\r\nrange:<l1>\r\ntarget:<l2>">;
		
	l2 = |project://test/src/main,java|(60,5,<11,0>,<14,0>);
	
	if(IsInRange(l1,l2))
		return <false, "at helpers::Location::IsInRange():Should NOT be in range!\r\nrange:<l1>\r\ntarget:<l2>">;

	return <true,"">;
}


private list[utr] TstLocSelectors()
{
	list[utr] results = [];
	
	loc source =  |project://test/src/main,java|(50,20,<11,1111>,<99,9999>);
	
	int exp = 11;
	int res = lineBgn(source);	
	if(exp != res)
		results += <false,"at helpers::Location::lineBgn()\r\nexpected:<exp>\r\nresult:<res>">;
	
	exp = 99;
	res = lineEnd(source);	
	if(exp != res)
		results += <false,"at helpers::Location::lineEnd()\r\nexpected:<exp>\r\nresult:<res>">;
		
	exp = 1111;
	res = colBgn(source);	
	if(exp != res)
		results += <false,"at helpers::Location::colBgn()\r\nexpected:<exp>\r\nresult:<res>">;
		
	exp = 9999;
	res = colEnd(source);	
	if(exp != res)
		results += <false,"at helpers::Location::colEnd()\r\nexpected:<exp>\r\nresult:<res>">;
		
	if(size(results) > 0)
		return results;
		
	return [<true,"">];
}


//helpers::m3
private utr TstFastResolveJava(M3 model)
{
	decl = getOneFrom(model@documentation)[0];
	loc exp = resolveJava(decl);
	loc res = FastResolveJava(model, decl);
	
	if(exp.uri != res.uri)
		return <false, "at helpers::m3::FastResolveJava()\r\ndecl:<decl>\r\nexp:<exp>\r\nres:<res>">;

	return <true,"">;
}

//helpers::string
private utr TstFilterStrSection()
{
	str source = "Hello world!";
	str exp = "Helrld!";
	str res = FilterStrSection(source, 3, 8);	
	
	if(exp != res)
		return <false, "at helpers::String::FilterStrSection()\r\nexp:<exp>\r\nres:<res>">;

	return <true,"">;
}



/*
 	FA test, do the clone detection results match with our expectations?
*/
public void StartFAT()
{
	expVol = 133;
	expClones = 56;
	expPerc = 42.13;
	expCcsNo = 3;
	expBig = 15;
	expCus = {"project://DuplicationExamples/src/utils.java",
				"project://DuplicationExamples/src/core.java",
				"project://DuplicationExamples/src/extension.java"};

	println("FAT start!\n");
	compilationUnits = GetSourceForTest();
	clones = FindClones(compilationUnits<1>);
	println("clone detection completed!\n");
	
	foundVol = compilationUnits<0>;
	foundClones = GetCloneTotal(clones);
	foundPerc = GetPercentage(foundClones, foundVol);
	foundCcsNo = size(domain(clones));
	
	set[list[str]] cls = domain(clones);
	int max = 0;
	list[str] bCl = [];
	for(c <- clones)
	{
		int s = size(c);
		if(s > max)
		{
			max = s;
			bCl = c;
		}
	}
	foundBig = size(bCl);
	set[str] foundCus = {};
	for(cc <- range(clones))
		foundCus += toSet([l | c <- cc, l := c[0].uri]); 
	
	PrintFTR("Volume\t",bool(){return expVol == foundVol;},expVol,foundVol);
	PrintFTR("CloneLOC",bool(){return expClones == foundClones;},expClones,foundClones);
	PrintFTR("ClonePerc",bool(){return expPerc == foundPerc;},expPerc,foundPerc);
	PrintFTR("# of CC\t",bool(){return expCcsNo == foundCcsNo;},expCcsNo,foundCcsNo);
	PrintFTR("Biggest\t",bool(){return expBig == foundBig;},expBig,foundBig);
	PrintFTR("Comp-units",bool(){return expCus == foundCus;},expCus,foundCus);
	if(passed) println("\ntests passed!");
	else println("\n1 or more tests failed!");
}

private str bts(bool() assertion)
{
	if(assertion())
		return "OK";
	
	passed = false;
	return "NOK";
}

private void PrintFTR(str name, bool() assertion, value e, value f) = println("<name>\t<bts(assertion)>\texpected:\t<e>\n\t\t\tfound:\t\t<f>\n");
private real GetPercentage(int num1, int num2) = round(toReal(num1)/toReal(num2)*100,0.11);