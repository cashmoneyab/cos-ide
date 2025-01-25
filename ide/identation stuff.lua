local test = [[
do
	do|
]];
local cursor = test:find("|");
if not cursor then
	error("Please put `|` as a placeholder for the cursor when the user actually presses enter~");
end


local rep = string.rep;
local source = test:sub(1,cursor-1) .. test:sub(cursor+1)

local identifers = {
	["do"] = function(ending, identationCount, endCount, newCursor)
		local start = "do\n" .. rep("\t", identationCount);

		local ends = "";
		if endCount >= 1 then
			ends = "\n" .. rep("\t", identationCount - 1) .. "end";
		end
		newCursor += #start;
		ending = start .. ends .. ending;
		return ending, newCursor;
	end,
	["then"] = function(ending, identationCount, endCount, newCursor)
		local start = "then\n" .. rep("\t", identationCount);

		local ends = "";
		if endCount >= 1 then
			ends = "\n" .. rep("\t", identationCount - 1) .. "end";
		end
		newCursor += #start;
		ending = start .. ends .. ending;
		return ending, newCursor;
	end,
	["function"] = function(ending, identationCount, endCount, newCursor)
		local start = "function (...)\n" .. rep("\t", identationCount);

		local ends = "";
		if endCount >= 1 then
			ends = "\n" .. rep("\t", identationCount - 1) .. "end";
		end
		newCursor += #start;
		ending = start .. ends .. ending;
		return ending, newCursor;
	end,
	["else"] = function(ending, identationCount, endCount, newCursor, beginning)
		local beginning = beginning:gsub("\t+$","") .. rep("\t", identationCount - 2);
		local start = "else\n" .. rep("\t", identationCount);

		newCursor += #start;
		ending = start .. ending;
		return ending, newCursor, beginning;
	end,
	["elseif"] = function(ending, identationCount, endCount, newCursor, beginning)
		local beginning = beginning:gsub("\t+$","") .. rep("\t", identationCount - 2);
		local start = "elseif then\n" .. rep("\t", identationCount);

		newCursor += #start;
		ending = start .. ending;
		return ending, newCursor, beginning;
	end,
	["while"] = function(ending, identationCount, endCount, newCursor)
		local start = "while do\n" .. rep("\t", identationCount);

		local ends = "";
		if endCount >= 1 then
			ends = "\n" .. rep("\t", identationCount - 1) .. "end";
		end
		newCursor += #start;
		ending = start .. ends .. ending;
		return ending, newCursor;
	end,
	["repeat"] = function(ending, identationCount, endCount, newCursor)
		local start = "repeat\nuntil";

		newCursor += 5;
		ending = start ..  ending;
		return ending, newCursor;
	end,
}

local function replaceWithFiller(s : string) : string
	return rep("\127",#s)
end

local function getIdens(source : string)
	return source
		:gsub('\127', '')
		:gsub("\\\"", "")
		:gsub("\\'", "")
		:gsub("\".-[\"\n]", replaceWithFiller)
		:gsub("'.-['\n]", replaceWithFiller)
		:gsub("%[=*%[.-%]=*%]", replaceWithFiller)
		:gsub("%-%-%[=*%[.-%]=*%]", replaceWithFiller)
		:gsub("%-%-[^\n]*", replaceWithFiller)
		:gsub("%-%-%[=*%[.*", replaceWithFiller)
		:gsub("%[=*%[.*", replaceWithFiller)
		:gsub("\".*", replaceWithFiller)
		:gsub("'.*", replaceWithFiller)
end

local function checkIdens(i : number, source : string)
	return source:sub(i,i) ~= "\127";
end;

local function startCount(source : string, i : number) -- getIdens
	local identationCount = 0;
	local endCount = 0;

	for iden in source:sub(1,i):gmatch("%w+") do
		if identifers[iden] then
			endCount += 1
			identationCount += 1
		end
		if iden == "end" then
			endCount -= 1;
			identationCount -= 1;
		end
	end

	for iden in source:sub(i+1):gmatch("%w+") do
		if identifers[iden] then
			endCount += 1
		end
		if iden == "end" then
			endCount -= 1;
		end
	end
	
	return identationCount, endCount, math.min(identationCount - endCount, 1);	
end

local i = cursor - 1
local word = source:sub(0, i):match("%w+$");
local autoFill = identifers[word]
if autoFill then -- identation and autofill
	if checkIdens(i, getIdens(source)) then
		local identationCount, endCount, correctedCount = startCount(source, i);
		local beginning = source:sub(1,(i - #word))
		local ending = source:sub(cursor);
		local newCursor = cursor;

		if not (ending.."\n"):match("%s*\n$") then
			return;
		end
		
		ending, newCursor, beg = autoFill(ending, identationCount, endCount, newCursor, beginning, correctedCount);
		if not newCursor then
			newCursor = cursor;
		end
		if beg then
			beginning = beg;
		end
		 
		print(beginning .. ending)
	end
elseif word == 1 then -- line identation
	local beginning = source:sub(1, cursor - #word + 1)
	local ending = source:sub(cursor);
end
