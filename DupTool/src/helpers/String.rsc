module helpers::String

import String;

public str FilterStrSection(str line, int sCol, int eCol) = substring(line, 0, sCol) + substring(line, eCol);