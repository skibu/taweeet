#!/usr/bin/env python3

import argparse
import sys
import urllib3


# For printing to stderr
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


# Parse command line args
parser = argparse.ArgumentParser(description='Gets JSON via a url and returns it')
parser.add_argument('-url', '--url', help='The url to be retrieved') 
args = parser.parse_args()

# Get the JSON from the URL
http = urllib3.PoolManager()
response = http.request("GET", args.url, headers={"Accept": "application/json, text/plain"})
if response.status != 200:
    eprint(f'Could not retrieve url={args.url} status={response.status}')
    sys.exit(1)

# Return the JSON simply by printing it to stdout
print(response.data.decode('utf-8'))

# Success
sys.exit(0)
