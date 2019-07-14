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
# import urllib.parse


def main():
    args = parse_arguments()
    set_logging(args.verbose, args.debug)
    if args.city_list:
        with open(args.city_list) as fp:
            cities = fp.readlines()
            cities = [x.strip() for x in cities]
    else:
        cities = [args.city]
    for city in cities:
        get_country(city)


def get_country(city_name):
    S = requests.Session()
    query = """SELECT DISTINCT ?item ?itemLabel ?country ?population ?countryName WHERE {{ ?item wdt:P31/wdt:P279* wd:Q515 .  ?item rdfs:label ?itemLabel .  FILTER (LANG(?itemLabel)="en") FILTER(CONTAINS(LCASE(?itemLabel), "{0}"@en)) .  ?item wdt:P1082 ?population .  ?item wdt:P17 ?country .  ?country rdfs:label ?countryName .  FILTER (LANG(?countryName)="en") }} ORDER BY DESC(?population) LIMIT 1"""
    
    URL = "https://query.wikidata.org/sparql"
    PARAMS = {
            "query": query.format(city_name.lower()),
            # "query": urllib.parse.quote(query.format(args.city)),
            'Accept': 'application/sparql-results+json',
            "format": "json"
    }
    log.debug(query.format(city_name.lower()))
    R = S.get(url=URL, params=PARAMS)
    log.debug(R.text)
    DATA = R.json()
    log.debug(DATA)
    try:
        country_name = DATA.get('results', {}).get('bindings', [])[0].get('countryName',{}).get('value',"")
        print("{0},{1}".format(city_name, country_name))
    except IndexError:
        print("{0},{1}".format(city_name, "UNKNOWN"))


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
    parser.add_argument("--city", "-c", help="City to use in query")
    parser.add_argument("--city_list", "-l", help="path to list of cities to use in query")
    
    args = parser.parse_args()
    return args

if __name__ == '__main__':
    main()
