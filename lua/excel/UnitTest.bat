@REM @Author: RonanLuo
@REM @Date:   2018-05-17 17:25:03
@REM @Last Modified by:   RonanLuo
@REM Modified time: 2018-05-17 17:34:03

@echo off
set /p filePath="Enter Excel path: "
set /p projPath="Enter project path: "
echo testStart, filePath:%filePath%, projPath:%projPath%
lua UnitTest.lua %filePath% %projPath%
pause