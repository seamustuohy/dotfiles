#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright © 2018 seamus tuohy, <code@seamustuohy.com>
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
import logging
import argparse
from os import path, getenv
from tempfile import gettempdir

from PyOrgMode import PyOrgMode
from datetime import datetime, timezone


def main(org_path):
    args = parse_arguments()
    set_logging(args.verbose, args.debug)

    if args.todo_states:
        todo_states = args.todo_states.split(',')

    orgfile = get_orgfile(args.org_path, args.todo_states)

    # Archive under project name
    project_name = get_entries_project(args.uuid, orgfile)
    archive_path = path.join(args.archive_folder_path, "{0}.org".format(project_name))

    entry = get_entry(args.uuid, orgfile.root)
    archive_entry(entry, orgfile, archive_path, update_origin=args.modify_origin_file)

    if args.modify_origin_file is True:
        write_orgfile(orgfile, org_path)

def archive_entry(entry, orgfile, archive_path, update_origin=False):
    write_entry(entry, archive_path)
    if update_origin is True:
        delete_entry(args.uuid, orgfile.root)

def archive_by_todo_state(root, orgfile, archive_path,
                          tag="COMPLETE", update_origin=False):
    property_filter = {"todo":tag}
    for node in root.content:
        if node.TYPE == 'NODE_ELEMENT':
            if match_node(property_filter, node):
                archive_entry(node, orgfile, archive_path,
                              update_origin=update_origin)
            else:
                archive_by_todo_state(root, orgfile, archive_path,
                                      tag=tag, update_origin=update_origin)

def match_node(properties, node):
    """
    To match the level of a node.
        properties = {"level":1}

    To match a specific set of tags:
        properties = {"tags":['hello', 'goodbye']}

    To match todo value
        properties = {"todo":"PENDING"}
    """
    for name,val in properties.items():
        if getattr(node, name, "FAIL") != val:
            return False
    return True


def delete_entry(uuid, root):
    for node in root.content:
        if node.TYPE == 'NODE_ELEMENT':
            delete_entry(uuid, node)
        elif node.name == 'PROPERTIES':
            for prop in node.content:
                if prop.name == "UUID":
                    if prop.value == uuid:
                        node.parent.parent.content.remove(node.parent)

def write_entry(entry, archive_path):
    archive_file = get_orgfile(archive_path)
    archive_file.root.append_clean(entry)


def get_entry(uuid, root):
    for node in root.content:
        if node.TYPE == 'NODE_ELEMENT':
            entry = get_entry(uuid, node)
            if entry is not False:
                return entry
        elif node.name == 'PROPERTIES':
            for prop in node.content:
                if prop.name == "UUID":
                    if prop.value == uuid:
                        return node.parent
    return False

def get_entries_project(uuid, base):
    for proj in base.root.content:
        if has_entry(uuid, proj):
            return proj

def has_entry(uuid, project):
    for node in project.content:
        try:
            for drawer in node.content:
                if drawer.name == "PROPERTIES":
                    for prop in drawer.content:
                        if prop.name == "UUID":
                            if prop.value == uuid:
                                return True
        except AttributeError:
            pass
    return False


def get_orgfile(org_path, todo_states=None):
    if todo_states is None:
        todo_states = []
    if org_path is None:
        org_path = get_org_path()
    base = PyOrgMode.OrgDataStructure()
    for state in todo_states:
        base.add_todo_state(state)
    try:
        base.load_from_file(path.abspath(org_path))
    except FileNotFoundError:
        base.save_to_file(path.abspath(org_path))
        base.load_from_file(path.abspath(org_path))
    return base

def write_orgfile(base, org_path):
    if org_path is None:
        org_path = get_org_path()
    base.save_to_file(path.abspath(org_path))


def get_org_path():
    env_path = getenv('ORG_TIMEW_FILE')
    if env_path is None:
        raise NameError("The path to an org file was not provided over the command line (--org_path) or set in an env variable (ORG_TIMEW_FILE). You must do one of these so we know what org file to write to.")
    return env_path

#################


def set_logging(verbose=False, debug=False):
    if debug is True:
        log.setLevel("DEBUG")
    elif verbose is True:
        log.setLevel("INFO")


def parse_arguments():
    parser = argparse.ArgumentParser("Taskwarrior hook to update modified items in an org file.")
    parser.add_argument("--debug", "-d",
                        help="Turn debugging on",
                        action='store_true')
    parser.add_argument("--org_path", "-f",
                        help="""Path of org-mode output file. This can also be set in the environment variable `ORG_TIMEW_FILE`.""")
    parser.add_argument("--todo_states", "-t",
                        help="""TODO states. If multiple they should be separated by commas.""",
                        default=[])

    args, unknown = parser.parse_known_args()
    return args

if __name__ == '__main__':
    logfilename = path.join(gettempdir(), "org-timew-hooks.log")
    logging.basicConfig(filename=logfilename, level=logging.ERROR)
    log = logging.getLogger(__name__)
    args = parse_arguments()
    main(args.org_path)
