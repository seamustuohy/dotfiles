#!/usr/bin/env python3

# 'get me all the urls and text for X style links from here a webpage'
# Used in my .functions/media snippets to download all files from a webpage with more appropriate names than anyone ever gives a file.
# Why do people release files with machine readable names and no legit exif title in the metadata? Seriously?!

# Imports

from bs4 import BeautifulSoup
from bs4.dammit import EncodingDetector
from urllib.parse import urlparse, urljoin
from os import path
import requests
# import ssl
# from requests.exceptions import Timeout, ConnectionError, SSLError
from urllib.parse import urlparse
# sudo -H pip3 install pyopenssl
# sudo apt-get install libssl-dev libffi-dev
# from OpenSSL import crypto
# from datetime import datetime
# import socket
from requests.packages.urllib3.exceptions import InsecureRequestWarning
# Scraping

def get_url(url, end_str, no_verify=True):
    # resp = get_request(url)
    if no_verify is True:
        verify = False
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    resp = requests.get(url, verify=verify)
    # print(resp.)
    http_encoding = resp.encoding if 'charset' in resp.headers.get('content-type', '').lower() else None
    html_encoding = EncodingDetector.find_declared_encoding(resp.content, is_html=True)
    encoding = html_encoding or http_encoding
    html = BeautifulSoup(resp.content, 'html.parser', from_encoding=encoding)
    raw = {}
    base_url = urlparse(url)
    base_url = "{0}://{1}".format(base_url.scheme, base_url.netloc)
    # print(base_url)
    for link in html.find_all('a', href=True):
        href = link['href']
        parsed_url=urlparse(href)
        # print(link['href'])
        if link['href'][0] == "/":
            # print("FOUND")
            # print(base_url)
            href = urljoin(base_url, href)
            parsed_url = urlparse(urljoin(base_url, link['href']))
            # print(parsed_url)
        extension = path.splitext(parsed_url.path)[1].strip(".")
        linktext = link.get_text()
        if  extension == end_str.strip("."):
            if raw.get(linktext, None) is None:
                raw[linktext] = href
            else:
                i = 1
                updated_linktext = "{0}_{1}".format(linktext, i)
                while raw.get(updated_linktext, None) is not None:
                    i += 1
                    updated_linktext = "{0}_{1}".format(linktext, i)
                raw[updated_linktext] = href
    return raw


# def get_request(url):
#     # Just do this...
#     # openssl s_client -connect $url:443
#     try:
#         resp = requests.get(url)# urlopen(url).read()
#     except SSLError as e:
#         # CHECK ERR_HOST_NOT_MATCH
#         errmsg = str(e)
#         if errmsg.startswith('hostname'):
#             raise ValueError("ERR_HOST_NOT_MATCH")

#         try:
#             u = urlparse(url)
#             raw_cert = ssl.get_server_certificate((u.netloc, 443))
#         except:
#             raise ValueError("ERR_UNKNOWN")
#         x509 = crypto.load_certificate(crypto.FILETYPE_PEM, raw_cert)

#         # CHECK ERR_EXPIRED
#         now = datetime.now()
#         not_after = datetime.strptime(x509.get_notAfter().decode('utf-8'),
#                                       "%Y%m%d%H%M%SZ")
#         not_before = datetime.strptime(x509.get_notBefore().decode('utf-8'),
#                                        "%Y%m%d%H%M%SZ")
#         if now > not_after or now < not_before:
#             raise ValueError("ERR_EXPIRED")

#         print(get_cert_info((u.netloc, 443)))

#         # otherwise ERR_SELF_SIGNED
#         raise ValueError("ERR_SELF_SIGNED")
#     except ConnectionError as e:
#         raise ValueError("ERR_TIMEOUT")
#     except Timeout as e:
#         raise ValueError("ERR_TIMEOUT")
#     except:
#          ValueError("ERR_UNKNOWN")
#     return resp

# def get_cert_info(addr, timeout=None):
#     with socket.create_connection(addr, timeout=timeout) as sock:
#         context = ssl.create_default_context()
#         with context.wrap_socket(sock, server_hostname=addr[0]) as sslsock:
#             return sslsock.getpeercert()


# Parse Arguments

def parse_arguments():
    arg_p = argparse.ArgumentParser("Get raw text from a url\n\nUrls and URL text are deliniated by four colons '::::'")
    arg_p.add_argument("-u", "--url", type=str, help="A url to parse.")
    arg_p.add_argument("-f", "--filetype", type=str, help="A url to parse.")
    arg_p.add_argument("-n", "--no-check-certificate", action='store_true', help="Use to not verify SSL certs (default true).")
    args = arg_p.parse_args()
    return args

# Main

if __name__ == '__main__':
    import sys
    import argparse
    args = parse_arguments()
    # print(args)
    raw = get_url(args.url, args.filetype, args.no_check_certificate)
    for text,url in raw.items():
        raw_output = "{0}::::{1}".format(url,text)
        print(raw_output)
    sys.exit(0)
