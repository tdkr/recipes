--[[--ldoc desc
@module UnitTest
@author RonanLuo

Date   2018-05-04 09:48:03
Last Modified by   RonanLuo
Last Modified time 2018-07-26 10:47:50
]]

local filePath = "D:/shengji/trunk/tools/UnitTest/test.xlsx";
local projPath = "D:/shengji/trunk/server/gzshengji_GameServer/Resource/scripts/GameServer/bin";
local s_FilePath = arg[1] or filePath;
local s_ProjPath = arg[2] or projPath;

require("luacom")
require("lfs")
require("luaiconv")
require("json")
local luaunit = require("luaunit")
local strsplit = luaunit.private.strsplit;
local g2u = iconv.new("UTF-8//IGNORE", "GB18030");
local u2g = iconv.new("GB18030//IGNORE", "UTF-8");
assert(g2u and u2g, "invalid char set!!!")

local s_App = luacom.GetObject("Excel.Application");
if s_App == nil then s_App = luacom.CreateObject("Excel.Application") end
s_App.visible = true;
local code, s_Workbook = pcall(function() return s_App.WorkBooks:Open(s_FilePath, 0, 0) end);
if not code then
	print("Open file failed!!!", s_Workbook);
	return;
end
local worksheets = s_Workbook.Sheets;
gprint = print;

local function copytab(tab)
	local t = {};
	for k,v in pairs(tab) do
		t[k] = v;
	end
	return t;
end

local s_Global = copytab(_G);
local s_PkgLoaded = copytab(package.loaded);
local function resetEnv( ... )
	for k,v in pairs(_G) do
		_G[k] = s_Global[k] ~= nil and s_Global[k] or nil;
	end
	for k,v in pairs(package.loaded) do
		package.loaded[k] = s_PkgLoaded[k] ~= nil and s_PkgLoaded[k] or nil;
	end
	-- print = function ( ... )
	-- 	-- body
	-- end
end

local function parseKeyInfo(sheet)
	local usedRange = sheet.UsedRange;
	local rows = usedRange.Rows;
	local cols = usedRange.Columns;
	local ret = {};
	local maxCol = 0;
	local maxRow = 0;
	for i=1,cols.Count do
		local cell = rows.Cells(1,i);
		if cell.Value2 then
			ret[cell.Value2] = i;
			maxCol = i;
		end
	end
	for i=3,rows.Count do
		local cell = rows.Cells(i,1);
		if cell.Value2 then
			maxRow = i;
		end
	end
	return ret, maxRow, maxCol;
end

local function testScript(testInfo)
	resetEnv();
	local scriptDir = s_ProjPath.."/"..testInfo.scriptDir;
	lfs.chdir(scriptDir)
	local m = require(testInfo.scriptName);
	local code, result,time = 
		pcall(function() return
			 m[testInfo.scriptFunc](testInfo) 
		 end)
	return code, result,time;
end

local function convertArgs(args)
	if not args then return end
	local argArr = strsplit("\n",args);
	local result = {};
	for i,argStr in ipairs(argArr) do
		local idx = string.find(argStr, "=");
		local k = string.sub(argStr, 1, idx-1);
		local v = string.sub(argStr, idx+1, string.len(argStr));
		k = g2u:iconv(k)
		v = g2u:iconv(v)
		table.insert(result, {k = k, v = v})
	end
	return result;
end

local function convertRuleArgs(args)
	if not args then return end
	local argArr = strsplit("\n",args);
	local result = {};
	for i,argStr in ipairs(argArr) do
		local idx = string.find(argStr, "=");
		local k = string.sub(argStr, 1, idx-1);
		local v = string.sub(argStr, idx+1, string.len(argStr));
		result[tonumber(k)] = g2u:iconv(v);
	end
	return result;
end

local function testSheet(sheet)
	local keyInfo, maxRow, maxCol = parseKeyInfo(sheet)
	-- gprint(sheet.Name, luaunit.prettystr(keyInfo), maxRow, maxCol)
	for i=3,maxRow do
		local testInfo = {};
		for k,v in pairs(keyInfo) do
			local value = sheet.Cells(i, v).Value2;
			-- 暂时注释，不做编码转换，编码转换过长会导致字符串截断
			-- if value and type(value) == "string" then
			-- 	value = g2u:iconv(value);
			-- end
			testInfo[k] = value;
		end
		local arr = strsplit("\n",testInfo.script);
		testInfo.scriptDir = string.match(arr[1], ".*/")
		testInfo.scriptFunc = arr[2];
		local arr2 = strsplit("/",arr[1]);
		testInfo.scriptName = arr2[#arr2]
		testInfo.args = convertArgs(testInfo.args);
		testInfo.ruleArgs = convertRuleArgs(testInfo.ruleArgs);
		local runningTime = 0
		local code, actualOutput,time
		for i=1,testInfo.times do
			 code, actualOutput,time = testScript(testInfo);
			runningTime = runningTime + time
			if code == false then
				break
			end 
		end
		local averageTime = runningTime/testInfo.times
		actualOutput = tostring(actualOutput)

		if code == false then
			testInfo.result = false;
		elseif testInfo.expectOutput then
			actualOutput = actualOutput and u2g:iconv(actualOutput);
			testInfo.result = actualOutput == testInfo.expectOutput;
		else
			actualOutput = actualOutput and u2g:iconv(actualOutput);
			testInfo.result = true;
		end
		sheet.Cells(i, keyInfo.actualOutput).Value2 = actualOutput;
		sheet.Cells(i, keyInfo.averageTime).Value2 = averageTime;
		sheet.Cells(i, keyInfo.result).Value2 = testInfo.result;
	end
end
	
lfs.chdir(s_ProjPath);
for i=1, worksheets.count do
	local sheet = worksheets(i)
	testSheet(sheet, s_ProjPath)
end

-- s_App.DisplayAlerts = false;
s_Workbook:Save();
-- s_App:Quit();