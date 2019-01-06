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
import datetime
import pytz
from win32com.propsys import propsys, pscon
from win32com.shell import shellcon
import pythoncom
import win32api
import dateutil.parser

pp = pprint.PrettyPrinter()

tz = pytz.timezone('Asia/Shanghai')

# e_msg = win32api.FormatMessage(-1072873842,)
# print(e_msg)


def checkfile0(filepath):
    properties = propsys.SHGetPropertyStoreFromParsingName(
        filepath, None, shellcon.GPS_READWRITE)
    dt = properties.GetValue(pscon.PKEY_Media_DateEncoded).GetValue()
    cdate = datetime.datetime.fromtimestamp(os.path.getctime(filepath))
    mdate = datetime.datetime.fromtimestamp(os.path.getmtime(filepath))
    value = propsys.PROPVARIANTType(cdate, pythoncom.VT_FILETIME)
    properties.SetValue(pscon.PKEY_Media_DateEncoded, value)
    print(dt, cdate, mdate)
    properties.Commit()
    
def utc_to_local(utc_dt):
    return utc_dt.replace(tzinfo=tz).astimezone(tz=None)

utc_now = tz.localize(datetime.datetime.utcnow())
datetags = ["QuickTime:CreateDate", "QuickTime:CreationDate", "QuickTime:MediaCreateDate", "QuickTime:TrackCreateDate"]
class DateFixer():
    def setUp(self):
        try:
            self.et = exiftool.ExifTool()
            self.et.start()
        except Exception as e:
            print(e)

    def fix_file(self, filepath):
        print("fix_file", filepath)
        metadata = self.et.get_metadata(filepath)
        cdate = utc_now
        for d in datetags:
            val = metadata[d]
            date = dateutil.parser.parse(val)
            ldate = utc_to_local(date)
            print(d, val, date)
            if cdate > ldate:
                cdate = ldate
        print(cdate)

    def stop(self):
        if self.et:
            self.et.terminate()


df = DateFixer()
df.setUp()
df.fix_file(r"C:\Users\luon\Downloads\IMG_0693.MOV")
df.stop()
