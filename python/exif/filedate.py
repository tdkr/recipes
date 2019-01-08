#!/usr/bin/python3

# ref:
# https://stackoverflow.com/questions/31507038/python-how-to-read-windows-media-created-date-not-file-creation-date/31530169#31530169
# https://docs.microsoft.com/en-us/windows/desktop/medfound/metadata-properties-for-media-files
# http://timgolden.me.uk/pywin32-docs/contents.html
# https://smarnach.github.io/pyexiftool/
# http://owl.phy.queensu.ca/~phil/exiftool/#running

import exiftool
import pprint
import os
from datetime import datetime
import time
import pytz
from win32com.propsys import propsys, pscon
from win32com.shell import shellcon
import pythoncom
import win32api

pp = pprint.PrettyPrinter()

cntz = pytz.timezone('Asia/Shanghai')

# e_msg = win32api.FormatMessage(-1072873842,)
# print(e_msg)


def checkfile0(filepath):
	properties = propsys.SHGetPropertyStoreFromParsingName(
		filepath, None, shellcon.GPS_READWRITE)
	dt = properties.GetValue(pscon.PKEY_Media_DateEncoded).GetValue()
	cdate = datetime.fromtimestamp(os.path.getctime(filepath))
	mdate = datetime.fromtimestamp(os.path.getmtime(filepath))
	value = propsys.PROPVARIANTType(cdate, pythoncom.VT_FILETIME)
	properties.SetValue(pscon.PKEY_Media_DateEncoded, value)
	print(dt, cdate, mdate)
	properties.Commit()

utc_now = datetime.utcnow()
datetags = ["QuickTime:CreateDate",	"QuickTime:MediaCreateDate", "QuickTime:TrackCreateDate"]


class DateFixer():
	def setUp(self):
		try:
			self.et = exiftool.ExifTool()
			self.et.start()
		except Exception as e:
			print(e)

	def fix_file(self, filepath):
		metadata = self.et.get_metadata(filepath)
		print("fix_file", filepath, metadata)
		cdate = datetime.strptime(metadata["QuickTime:CreationDate"], "%Y:%m:%d %H:%M:%S%z")
		cpath = bytes(filepath, encoding = "utf-8")
		for i in datetags:
			args = bytes('-{0}="{1}"'.format(i, cdate), encoding = "utf-8")
			try:
				output = self.et.execute(args, cpath)
				print("output===", output)
			except Exception as e:
				print(e)

	def stop(self):
		if self.et:
			self.et.terminate()


df = DateFixer()
df.setUp()
df.fix_file(r"IMG_0767.MOV")
df.stop()
