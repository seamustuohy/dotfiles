#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright © 2019 seamus tuohy, <code@seamustuohy.com>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the included LICENSE file for details.



####################
# WARNING: This will cause errors in the file.
# But, it will still open and allow you to copy the text so who cares.
####################

import argparse
import zipfile
import xml.etree.ElementTree
import re

from os.path import splitext
from shutil import copyfile
import logging
logging.basicConfig(level=logging.ERROR)
log = logging.getLogger(__name__)

def main():
    args = parse_arguments()
    set_logging(args.verbose, args.debug)
    if args.outfile:
        write_new_zipfile(args.infile, args.outfile)
    else:
        path,extension = splitext(args.infile)
        updatedfile = path + "_unprotected" + extension
        write_new_zipfile(args.infile, updatedfile)


def write_new_zipfile(zipname, out_file_name, target_file="word/settings.xml"):
    with zipfile.ZipFile(zipname, 'r') as zin:
        with zipfile.ZipFile(out_file_name, 'w') as zout:
            zout.comment = zin.comment # preserve the comment
            for item in zin.infolist():
                if item.filename != target_file:
                    zout.writestr(item, zin.read(item.filename))
                else:
                    set_namespaces(zin.open(item.filename, 'r'))
                    new_settings = remove_setting_protection(zin.read(item.filename))
                    zout.writestr(item, new_settings)

def set_namespaces(filepointer):
    events = "start-ns",
    for event, elem in xml.etree.ElementTree.iterparse(filepointer, events):
           if event == "start-ns":
               xml.etree.ElementTree.register_namespace(elem[0], elem[1])


def remove_setting_protection(settings):
    dec = re.match("^.*\?>", settings.decode("UTF-8")).group()
    # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>    
    root = xml.etree.ElementTree.fromstring(settings)
    for child in root:
        if child.tag == '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}documentProtection':
            log.info("documentProtection found")
            child.attrib = {}
    updated_text = xml.etree.ElementTree.tostring(root)
    updated_text = dec.encode() + updated_text
    log.debug(updated_text)
    return updated_text


# Command Line Functions below this point

def set_logging(verbose=False, debug=False):
    if debug == True:
        log.setLevel("DEBUG")
    elif verbose == True:
        log.setLevel("INFO")

def parse_arguments():
    parser = argparse.ArgumentParser("package name")
    parser.add_argument("--verbose", "-v",
                        help="Turn verbosity on",
                        action='store_true')
    parser.add_argument("--debug", "-d",
                        help="Turn debugging on",
                        action='store_true')
    parser.add_argument("--infile", "-i",
                        help="Path to docx to unprotect",
                        required=True)
    parser.add_argument("--outfile", "-o",
                        help="Path to write unprotected docx to (Optional)")
    args = parser.parse_args()
    return args

def usage():
    print("TODO: usage needed")

if __name__ == '__main__':
    main()
