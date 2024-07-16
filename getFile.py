#!/usr/bin/env python3

import argparse
import sys
import urllib3


# For printint to stderr
def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


# Parse command line args
parser = argparse.ArgumentParser(description='Gets an image via a url and stores it in file')
parser.add_argument('-url', '--url', help='The url to be retrieved') 
parser.add_argument('-fileName', '--fileName', help='Name of file where data to be stored')
parser.add_argument('-fileType', '--fileType', help='Type of file. "wav" or "png"', default='png') 
args = parser.parse_args()

# Get the file from the URL
http = urllib3.PoolManager()
response = http.request("GET", args.url)
if response.status != 200:
    eprint(f'Could not retrieve url={args.url} status={response.status}')
    sys.exit(1)

# Write the file
with open(args.fileName, "wb") as file:
    file.write(response.data)

# Success
sys.exit(0)
