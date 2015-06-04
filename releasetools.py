# Copyright (C) 2015 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Emit commands needed for ZTE devices during OTA installation
(installing the aboot/modem/rpm/sbl/tz/bluetooth/hyp/pmic images)."""

import common
import re
import sha

def FullOTA_Assertions(info):
  AddBasebandAssertion(info)
  return

def IncrementalOTA_Assertions(info):
  AddBasebandAssertion(info)
  return

def InstallImage(img_name, img_file, partition, info):
  common.ZipWriteStr(info.output_zip, img_name, img_file)
  info.script.AppendExtra(('package_extract_file("' + img_name + '", "/dev/block/bootdevice/by-name/' + partition + '");'))

image_partitions = {
   'emmc_appsboot.mbn' : 'aboot',
   'rpm.mbn'           : 'rpm',
   'tz.mbn'            : 'tz',
   'hyp.mbn'           : 'hyp',
   'sdi.mbn'           : 'sdi',
   'pmic.mbn'          : 'pmic',
   'BTFM.bin'          : 'bluetooth',
   'NON-HLOS.bin'      : 'modem',
   'splash.img'        : 'splash',
   'sbl1.mbn'          : 'sbl1'
}

def FullOTA_InstallEnd(info):
  info.script.Print("Writing radio image...")
  for k, v in image_partitions.iteritems():
    try:
      img_file = info.input_zip.read("RADIO/" + k)
      info.script.Print("update image " + k + "...")
      InstallImage(k, img_file, v, info)
    except KeyError:
      print "warning: no " + k + " image in input target_files; not flashing " + k


def IncrementalOTA_InstallEnd(info):
  for k, v in image_partitions.iteritems():
    try:
      source_file = info.source_zip.read("RADIO/" + k)
      target_file = info.target_zip.read("RADIO/" + k)
      if source_file != target_file:
        InstallImage(k, target_file, v, info)
      else:
        print k + " image unchanged; skipping"
    except KeyError:
      print "warning: " + k + " image missing from target; not flashing " + k

def AddBasebandAssertion(info):
  android_info = info.input_zip.read("OTA/android-info.txt")
  m = re.search(r'require\s+version-baseband\s*=\s*(\S+)', android_info)
  if m:
    versions = m.group(1).split('|')
    if len(versions) and '*' not in versions:
      cmd = 'assert(nx510j.verify_baseband(' + ','.join(['"%s"' % baseband for baseband in versions]) + ') == "1");'
      info.script.AppendExtra(cmd)
  return
