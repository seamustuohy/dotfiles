#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright © 2026 seamus tuohy, <code@seamustuohy.com>
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
import requests
import logging
logging.basicConfig(level=logging.ERROR)
log = logging.getLogger(__name__)
import json

# Only needed for decoding readme content
# from base64 import b64decode



def main():
    args = parse_arguments()
    set_logging(args.verbose, args.debug)
    if args.access_token is None:
        access_token = input("Paste access token here: ")
    else:
        access_token = args.access_token

    info = get_repo_info(args.user, args.repo, access_token)
    print(info)
    # b64decode(info['readme']['content'])


    # embed()


def get_repo_info(owner, repo, token):
    # Standard headers for GitHub API v3
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    url = 'https://api.github.com/repos/{0}/{1}'.format(owner, repo)
    r = requests.get(url, headers=headers)
    info = r.json()
    readme_url = url + '/readme'
    r = requests.get(readme_url, headers=headers)
    info['readme'] = r.json()
    return info

def embed():
    import os
    import readline
    import rlcompleter
    import code
    import inspect
    import traceback

    history = os.path.join(os.path.expanduser('~'), '.python_history')
    if os.path.isfile(history):
        readline.read_history_file(history)

    frame = inspect.currentframe().f_back
    namespace = frame.f_locals.copy()
    namespace.update(frame.f_globals)

    readline.set_completer(rlcompleter.Completer(namespace).complete)
    readline.parse_and_bind("tab: complete")

    file = frame.f_code.co_filename
    line = frame.f_lineno
    function = frame.f_code.co_name

    stack = ''.join(traceback.format_stack()[:-1])
    print(stack)
    banner = f" [ {os.path.basename(file)}:{line} in {function}() ]"
    banner += "\n Entering interactive mode (Ctrl-D to exit) ..."
    try:
        code.interact(banner=banner, local=namespace)
    finally:
        readline.write_history_file(history)

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
    parser.add_argument("--access_token", "-a",
                        help="github access token")
    parser.add_argument("--repo", "-r",
                        help="repo name",
                        required=True)
    parser.add_argument("--user", "-u",
                        help="user name",
                        required=True)

    args = parser.parse_args()
    return args

if __name__ == '__main__':
    main()
