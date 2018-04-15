#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright © 2017 seamus tuohy, <s2e@seamustuohy.com>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the included LICENSE file for details.

import sys
import json
import fileinput
from collections import namedtuple

import logging
logging.basicConfig(level=logging.ERROR)
log = logging.getLogger(__name__)


def main():
    report = TimeWarriorReport()
    # timew arbtt
    # TODO Check for 'arbtt' in temp.report.tags
    for n,v in report.headers.items():
        print(n,v)
    print(report.body)
    log.info("Starting TimeWarrior input")
    #print("Hello")
    #data = read_timew()
    ##print(dir(data))

class TimeWarriorReport():

    def __init__(self):
        self.headers = {}
        self.raw = ''
        self.body = None
        self.parse_report()
        self.parse_body()

    def parse_report(self):
        header = True
        for line in fileinput.input():
            if header is True:
                if line == '\n':
                    header = False
                else:
                    _config = self.add_header(line)
                    self.headers[_config.name] = _config.val
            else:
                self.raw += line

    def parse_body(self):
        self.body = json.loads(self.raw)

    def add_header(self, line):
        Config = namedtuple('config', ['name', 'val'])
        fields = line.strip().split(': ', 2)
        if len(fields) == 2:
            config = Config(name=fields[0],
                            val=fields[1])
        else:
            config = Config(name=fields[0],
                            val='')
        return config

def read_timew():
    data = json.load(sys.stdin)
    return data

# Command Line Functions below this point

def set_logging(verbose=False, debug=False):
    if debug == True:
        log.setLevel("DEBUG")
    elif verbose == True:
        log.setLevel("INFO")

if __name__ == '__main__':
    print("THIS CODE DOES NOT WORK CURRENTLY.")
    print("IT'S JUST HERE FOR ONE DAY WHEN I HAVE TIME.")
    sys.exit()
    main()
