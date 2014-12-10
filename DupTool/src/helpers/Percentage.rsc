module helpers::Percentage

import util::Math;

//return percentage of num1 in num2, decimal precison:2
public real GetPercentage(int num1, int num2) = precision(toReal(num1)/toReal(num2)*100,4);