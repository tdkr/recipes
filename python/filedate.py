#!/usr/bin/python3

# ref:
# https://stackoverflow.com/questions/31507038/python-how-to-read-windows-media-created-date-not-file-creation-date/31530169#31530169
# https://docs.microsoft.com/en-us/windows/desktop/medfound/metadata-properties-for-media-files
# http://timgolden.me.uk/pywin32-docs/contents.html

import piexif
import pprint
import os
import datetime
import pytz
import datetime
from win32com.propsys import propsys, pscon
from win32com.shell import shellcon
import pythoncom
import win32api

pp = pprint.PrettyPrinter()

# e_msg = win32api.FormatMessage(-1072873842,)
# print(e_msg)

def checkfile(filepath):
    # with piexif.load(filepath) as exif_dict:
    # 	edatestr = exif_dict["Exif"][piexif.ExifIFD.DateTimeOriginal].decode("utf-8")
    # 	edate = datetime.datetime.strptime(edatestr,'%Y:%m:%d %H:%M:%S')
    properties = propsys.SHGetPropertyStoreFromParsingName(filepath, None, shellcon.GPS_READWRITE)
    dt = properties.GetValue(pscon.PKEY_Media_DateEncoded).GetValue()
    cdate = datetime.datetime.fromtimestamp(os.path.getctime(filepath))
    mdate = datetime.datetime.fromtimestamp(os.path.getmtime(filepath))
    value = propsys.PROPVARIANTType(cdate, pythoncom.VT_FILETIME)
    properties.SetValue(pscon.PKEY_Media_DateEncoded, value)
    print(dt, cdate, mdate)
    properties.Commit()


checkfile(r"C:\Users\luon\Downloads\IMG_0693.MOV")