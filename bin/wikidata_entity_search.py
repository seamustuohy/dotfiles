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

import argparse

import logging
logging.basicConfig(level=logging.ERROR)
log = logging.getLogger(__name__)

import requests



def main():
    args = parse_arguments()
    set_logging(args.verbose, args.debug)
    S = requests.Session()
    URL = "https://www.wikidata.org/w/api.php"
    SEARCHTERM = args.search_term
    PARAMS = {
            "action": "wbsearchentities",
            "format": "json",
            "search": SEARCHTERM,
            "language": "en"
    }
    R = S.get(url=URL, params=PARAMS)
    DATA = R.json()
    for i in DATA.get('search', []):
        print(i.get('id',""),
              i.get('url',""),
              i.get('label',""),
              i.get('description',""))
        print("\n")
    #print(DATA)    


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
    parser.add_argument("--search_term", "-s", help="Search term to use in query", required=True)
    args = parser.parse_args()
    return args

if __name__ == '__main__':
    main()


