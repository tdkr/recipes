@echo off
set curDir=%~dp0

cd /D %curDir%

set importPath=%curDir%..\..\..\

protoc -I=%importPath% %importPath%game\net\pb\Game.proto %importPath%common\net\pb\Common.proto -o %importPath%game\net\pb\GameProto.pb

@echo finished

pause