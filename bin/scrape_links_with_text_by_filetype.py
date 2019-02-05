#!/usr/bin/env python3

# 'get me all the urls and text for X style links from here a webpage'
# Used in my .functions/media snippets to download all files from a webpage with more appropriate names than anyone ever gives a file.
# Why do people release files with machine readable names and no legit exif title in the metadata? Seriously?!

# Imports

from bs4 import BeautifulSoup
from bs4.dammit import EncodingDetector
from urllib.parse import urlparse
from os import path
import requests


# Scraping

def get_url(url, end_str):
    resp = requests.get(url)# urlopen(url).read()
    http_encoding = resp.encoding if 'charset' in resp.headers.get('content-type', '').lower() else None
    html_encoding = EncodingDetector.find_declared_encoding(resp.content, is_html=True)
    encoding = html_encoding or http_encoding
    html = BeautifulSoup(resp.content, 'html.parser', from_encoding=encoding)
    raw = {}
    for link in html.find_all('a', href=True):
        parsed_url=urlparse(link['href'])
        extension = path.splitext(parsed_url.path)[1].strip(".")
        linktext = link.get_text()
        if  extension == end_str.strip("."):
            if raw.get(linktext, None) is None:
                raw[linktext] = link['href']
            else:
                i = 1
                updated_linktext = "{0}_{1}".format(linktext, i)
                while raw.get(updated_linktext, None) is not None:
                    i += 1
                    updated_linktext = "{0}_{1}".format(linktext, i)
                raw[updated_linktext] = link['href']
    return raw

# Parse Arguments

def parse_arguments():
    arg_p = argparse.ArgumentParser("Get raw text from a url\n\nUrls and URL text are deliniated by four colons '::::'")
    arg_p.add_argument("-u", "--url", type=str, help="A url to parse.")
    arg_p.add_argument("-f", "--filetype", type=str, help="A url to parse.")
    args = arg_p.parse_args()
    return args

# Main

if __name__ == '__main__':
    import sys
    import argparse
    args = parse_arguments()
    raw = get_url(args.url, args.filetype)
    for text,url in raw.items():
        raw_output = "{0}::::{1}".format(url,text)
        print(raw_output)
    sys.exit(0)
