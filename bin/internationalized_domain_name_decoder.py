#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright © 2017 seamus tuohy, <code@seamustuohy.com>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the included LICENSE file for details.

# Decodes internationalized domain names
# Takes in an ASCII-compatible encoding (ACE) format and
# outputs the UTF encoding.
#
# Should work on RFC 3490 (Internationalized Domain Names in Applications) and
# RFC 3492 (Nameprep: A Stringprep Profile for Internationalized Domain Names (IDN))
#
# References
# - https://tools.ietf.org/html/rfc3490
# - https://tools.ietf.org/html/rfc3492
# - https://docs.python.org/3/library/codecs.html#module-encodings.idna
# - https://www.symantec.com/connect/blogs/bad-guys-using-internationalized-domain-names-idns
# - https://www.w3.org/International/articles/idn-and-iri/
# - https://www.w3.org/International/articles/idn-and-iri/#phishing
import argparse
import idna
from urllib.parse import urlparse

import logging
logging.basicConfig(level=logging.ERROR)
log = logging.getLogger(__name__)


def main():
    args = parse_arguments()
    set_logging(args.verbose, args.debug)
    netloc = get_netloc(args.raw_domain)
    print(decode_domain(netloc))

def get_netloc(raw_domain):
    parsed_raw = urlparse(raw_domain)
    log.debug("parsed url == {0}".format(parsed_raw))
    if parsed_raw.netloc == '':
        netloc = parsed_raw.path
    else:
        netloc = parsed_raw.netloc
    log.debug("netloc identified == {0}".format(netloc))
    return netloc

def decode_domain(raw):
    ACE_prefix = 'xn--'
    if ACE_prefix not in raw:
        err_msg = "Domain that was provided was not a proper IDNA formatted string."
        log.error(err_msg)
        raise ValueError(err_msg)
    try:
        domain = idna.decode(raw)
        idna.core.InvalidCodepoint
    except idna.core.InvalidCodepoint:
        # Try Compatibility Mapping
        domain = idna.decode(raw, uts46=True)
    return domain

# Command Line Functions below this point

def set_logging(verbose=False, debug=False):
    if debug is True:
        log.setLevel("DEBUG")
    elif verbose is True:
        log.setLevel("INFO")

def parse_arguments():
    parser = argparse.ArgumentParser("Get a summary of some text")
    parser.add_argument("raw_domain")
    parser.add_argument("--verbose", "-v",
                        help="Turn verbosity on",
                        action='store_true')
    parser.add_argument("--debug", "-d",
                        help="Turn debugging on",
                        action='store_true')
    args = parser.parse_args()
    return args

def usage():
    print("TODO: usage needed")

if __name__ == '__main__':
    main()
