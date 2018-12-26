#!/usr/bin/python3
import json
import types
import os


def space_str(layer):
	spaces = ""
	for i in range(0, layer):
		spaces += '\t'
	return spaces


def dic_to_lua_str(data, layer=0):

	d_type = type(data)
	if isinstance(data, str):
		if data.find("\n") != -1:
			yield ("[[" + data + "]]")
		else:
			yield ("'" + data + "'")
	elif isinstance(data, bool):
		if data:
			yield ('true')
		else:
			yield ('false')
	elif isinstance(data, int):
		yield (str(data))
	elif isinstance(data, list):
		yield ("{\n")
		yield (space_str(layer+1))
		for i in range(0, len(data)):
			for sub in dic_to_lua_str(data[i], layer+1):
				yield sub
			if i < len(data)-1:
				yield (',')
		yield ('\n')
		yield (space_str(layer))
		yield ('}')
	elif isinstance(data, dict):
		yield ("\n")
		yield (space_str(layer))
		yield ("{\n")
		data_len = len(data)
		data_count = 0
		for k, v in data.items():
			data_count += 1
			yield (space_str(layer+1))
			# yield ('["' + str(k) + '"]')
			if isinstance(k, int):
				yield ('[' + str(k) + ']')
			else:
				yield ('["' + k + '"]')
			yield (' = ')
			try:
				for sub in dic_to_lua_str(v, layer + 1):
					yield sub
				if data_count < data_len:
					yield (',\n')
			except Exception as e:
				print('error in ',k,v,e)
				raise
		yield ('\n')
		yield (space_str(layer))
		yield ('}')
	else:
		yield ('nil')
		# raise d_type , 'is error'

def str_to_lua_table(jsonStr):
	data_dic = None
	try:
		data_dic = json.loads(jsonStr)
	except Exception as e:
		print(e)
		data_dic =[]
	else:
		pass
	finally:
		pass
	bytes = ''
	for it in dic_to_lua_str(data_dic):
		bytes += it
	return bytes

def file_to_lua_file(jsonFile,luaFile):
	with open(luaFile,'w') as luafile:
		with open(jsonFile) as jsonfile:
			luafile.write(str_to_lua_table(jsonfile.read()))

def dict_to_lua_table(data, name):
	luastr = ""
	it = dic_to_lua_str(data)
	for x in it:
		luastr = luastr + x
	return "do local {0} = {1}{2}return {0}{2}end".format(name, luastr, os.linesep)
