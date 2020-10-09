-- https://stackoverflow.com/questions/33988610/weird-behavior-of-syntax-sugarcolon-in-lua

debug.setmetatable(0, {__index = math})
local x = 5.7
print(x:floor())

debug.setmetatable(function()end,{__index=coroutine})
print:create():resume()