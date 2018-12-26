import jsontolua

dt = {
	"a":1,
	"b":2,
	"c":{
		"e":3,
		"f":4
	},
	"d":[1,2,3],
}

tb = jsontolua.dict_to_lua_table(dt, "pydt")
print(tb)