module helpers::String

import String;

//filter the given section of a string
public str FilterStrSection(str line, int sCol, int eCol) = substring(line, 0, sCol) + substring(line, eCol);