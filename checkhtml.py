import os
import re
import html5lib
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("path")
args = parser.parse_args()

html5parser = html5lib.HTMLParser(strict=True)
for filename in os.listdir(args.path):
    if filename.endswith(".html"):
        try:
            with open(os.path.join(args.path, filename), "r", encoding='utf-8') as h:
                html = h.read()
            # Add missing doctype
            if not re.search("^\<!DOCTYPE", html, re.MULTILINE + re.UNICODE):
                html = "<!DOCTYPE html>" + html
            html5parser.parse(html)
        except Exception as e:
            print(f"Error while processing {filename}:\n{e}")
