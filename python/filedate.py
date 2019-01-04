#!/usr/bin/python3

import piexif
import win32file, win32com
import pprint
import os
import datetime

pp = pprint.PrettyPrinter()

def checkfile(filepath):
	exif_dict = piexif.load(filepath)
	edatestr = exif_dict["Exif"][piexif.ExifIFD.DateTimeOriginal].decode("utf-8")
	edate = datetime.datetime.strptime(edatestr,'%Y:%m:%d %H:%M:%S')
	cdate = datetime.datetime.fromtimestamp(os.path.getctime(filepath))
	mdate = datetime.datetime.fromtimestamp(os.path.getmtime(filepath))
	print(edate, cdate, mdate, cdate < edate, mdate < edate)
