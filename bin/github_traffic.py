#!/usr/bin/env python

#Original Code
#https://github.com/winter-muted/moose/blob/399aefb8d7d62e0163045b39803a2d791ada04f9/scripts/github_traffic.py

# For automated logging:
# python github_traffic.py --log --user [USERNAME] --password [PASSWORD]

from http import cookiejar
# import cookielib
import sys, os, time, argparse, getpass, re, datetime, csv

try:
    import mechanize
except ImportError:
    print('python-mechanize module not available.\n')
    sys.exit(1)


def get_via_api(repos, password, minimal=False):
    import requests
    # p = getpass.getpass(prompt='Password')
    headers = {'Authorization': 'token {0}'.format(password)}
    minimal_stats = ['/traffic/views']
    stats_paths = ['/traffic/popular/paths',
                   '/traffic/popular/referrers',
                   '/traffic/views',
                   '/traffic/clones']
    if minimal is True:
        stats_paths = minimal_stats
    for repo in repos:
        print("Repo Name: {0}".format(repo))
        if minimal is False:
            print("\n\n")
        for path in stats_paths:
            url = 'https://api.github.com/repos/{0}{1}'.format(repo, path)
            r = requests.get(url, headers=headers)
            if minimal is False:
                print('\n---\n')
                print(url)
            print_stats(r.json(), path, minimal)
        if minimal is False:
            print("\n--------------------------------------------\n")

def print_stats(data, stat_type, minimal=False):
    #print(data, stat_type)
    if stat_type == '/traffic/views':
        if minimal is True:
            print("Count: {0: <5} \tUnique: {1: <5}".format(data.get('count', 0), data.get('uniques', 0)))
        else:
            for view_data in data.get('views', []):
                for i in view_data:
                    print(i)
    else:
        print(data)
        # for i in data:
        #     print(i)


def webBrowser():
    # Browser
    br = mechanize.Browser()
    br.set_debug_http(True)

    # Cookie Jar
    cj = cookiejar.LWPCookieJar()
    br.set_cookiejar(cj)

    # Browser options
    br.set_handle_equiv(True)
    br.set_handle_gzip(False)
    br.set_handle_redirect(True)
    br.set_handle_referer(True)
    br.set_handle_robots(False)
    br.set_handle_refresh(mechanize._http.HTTPRefreshProcessor(), max_time=1)
    br.addheaders = [('User-agent', 'Chrome')]

    # The site we will navigate into, handling it's session
    br.open('https://github.com/login')

    # Select the first (index 0) form
    # There used to be a search box, if you get an error here they might have added it back.
    # this changes from web site to web site. GitHub.com/login happens to be the second form
    br.select_form(nr=0)
    return br

def authenticatePage(user, password):

    browser = webBrowser()
    browser.form['login'] = user
    browser.form['password'] = password
    browser.submit()
    return browser

def readPage(browser, repo):
    stats = {}
    browser.addheaders = [('User-agent', 'Chrome'), ('Referer', 'https://github.com/' + repo + '/graphs/traffic'), ('X-Requested-With', 'XMLHttpRequest')]
    # GitHubs Traffic payload is in python dictionary format
    # grab the clones, and Visitors
    try:
        stats['Clones'] = eval(browser.open('https://github.com/' + repo + '/graphs/clone-activity-data').read())
        stats['Visitors'] = eval(browser.open('https://github.com/' + repo + '/graphs/traffic-data').read())
    except mechanize.HTTPError as e:
        print('There was an error obtaining traffic for said site.')
        if str(e).find('406') != -1:
            print('\tError 406: You do not have permission to view statistics. Or you supplied incorrect credentials')
            sys.exit(1)
        if str(e).find('404') != -1:
            print('\tError 404: Page not found')
            sys.exit(1)
    return stats

def verifyArgs(args):
    if args.user is '':
        print('\nYou must specify a user to authenticate with')
        sys.exit(1)
    try:
        while args.password is '':
            args.password = getpass.getpass('Password for UserID ' + args.user + ' :',)
    except KeyboardInterrupt:
        print('')
        sys.exit(0)
    return args

def write_list(dev_data, writefile):
        with open(writefile, 'w+') as csvfile:
                csvw = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                for i in dev_data:
                        csvw.writerow(i)

def get_csv(filename):
        with open(filename, 'r') as csvfile:
                reader= csv.reader(csvfile)
                csvlist = list(reader)
        return csvlist


def writeFile(writefile, stats):
    if os.path.isfile(writefile):
        log_file = get_csv(writefile)

        merged = {}
        for log in log_file:
            merged[(log[0], log[1])] = log
        for stat in stats:
            merged[(stat[0], stat[1])] = stat

        updated = []
        for i in merged:
            updated.append(merged[i])
    else:
        updated = stats

    # sort list by date (in-place)
    updated.sort(key=lambda x: datetime.datetime.strptime(x[0], "%Y-%b-%d"))

    write_list(updated, writefile)

def parseArgs(args=None):
    # Traffic Stats URL: https://github.com/idaholab/moose/graphs/clone-activity-data
    parser = argparse.ArgumentParser(description='Scrape GitHub for a webpage requiring authentication')
    parser.add_argument('--repo', '-r', nargs='?', help='Repository (example: foo/bar)')
    parser.add_argument('--log', '-l', help='Write stats to the default log location.', action='store_true')
    parser.add_argument('--minimal', '-m', help='Just get minimal information on stats.', action='store_true')
    parser.add_argument('--write', '-w', nargs='?', help='Write to a file')
    try:
        parser.add_argument('--user', '-u', nargs='?', default=os.getenv('USER'), help='Authenticate using specified user. Defaults to: (' + os.getenv('USER') + ')')
    except TypeError:
        parser.add_argument('--user', '-u', nargs='?', default='', help='Authenticate using specified user')
    parser.add_argument('--password', '-p', nargs='?', default='', help='Authenticate using specified password')
    return verifyArgs(parser.parse_args(args))

if __name__ == '__main__':
    args = parseArgs()
    with open("/home/s2e/dotfiles/private/scraping/github_repos.txt") as fp:
        repos = fp.readlines()
        repos = [x.strip() for x in repos]
    get_via_api(repos, args.password, args.minimal)

    # web_page = authenticatePage(args.user, args.password)
    # clones = []
    # visits = []
    # for repo in repos:
    #     print("pulling {0}".format(repo))
    #     payload = readPage(web_page, repo)
    #     stats = {'clones'     : [],
    #                      'visitors' : []}
    #     for point in payload['Clones']['counts']:
    #         clones.append([time.strftime("%Y-%b-%d", time.gmtime(point['bucket'])), repo, str(point['total']), str(point['unique'])])
    #     for point in payload['Visitors']['counts']:
    #         visits.append([time.strftime("%Y-%b-%d", time.gmtime(point['bucket'])), repo, str(point['total']), str(point['unique'])])

    #print("found clones {0}".format(clones))
    #print("found visits {0}".format(clones))
    # if args.write:
    #     print("writing to files")
    #     writeFile("{0}.clones.csv".format(args.write), clones)
    #     writeFile("{0}.visits.csv".format(args.write), visits)
    # elif args.log:
    #     print("writing to default log files")
    #     writeFile("/tmp/github.clones.csv", clones)
    #     writeFile("/tmp/github.visits.csv", visits)
    # else:
    #     print '\nClones: (date, total, unique)\n', stats['clones']
    #     print '\nVisitors: (date, total, unique)\n', stats['visitors']
