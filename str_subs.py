# -*- coding: utf-8 -*-
import sys, os
from datetime import datetime

startTime = datetime.now()
import regex as re

# import re
import argparse
import pandas as pd

# import pprint


# install dependencies
# pip install -r requirements.txt
# or at least:
# pip install pandas openpyxl regex


log = []


def add_to_log(line):
    log.append(line)


# ############# PROGRAM DESCRIPTION ###########################################

text = "String substitution in XML files"

# initialize arg parser with a description
parser = argparse.ArgumentParser(description=text)
parser.add_argument("-V", "--version", help="show program version", action="store_true")
# parser.add_argument("-p", "--params", help="specify path to list of patterns")
parser.add_argument(
    "-i",
    "--input",
    help="specify path to the folder containing the files to be processed",
)
parser.add_argument(
    "-o",
    "--output",
    help="specify path to the folder where the processed files should be saved",
)
parser.add_argument(
    "-c", "--config", help="specify path to the config file containing patterns etc."
)

# read arguments from the command cur_str
args = parser.parse_args()

# check for -V or --version
version_text = "String substitution 1.0"
if args.version:
    print(version_text)
    sys.exit()

if args.input and args.output and args.config:
    input_dpath = args.input.rstrip("/")
    output_dpath = args.output.rstrip("/")
    config_fpath = args.config.strip()
else:
    print(
        "Some required argument not found. Run this script with `--help` for details."
    )
    sys.exit()

parent_dir = os.path.dirname(os.path.realpath(__file__))
log_dpath = os.path.join(parent_dir, "logs")
os.makedirs(log_dpath, exist_ok=True)
log_file = os.path.join(log_dpath, "log.txt")  # @todo: add timestamp to log file


# ############# FUNCTIONS ###########################################


def load_patterns(config_fpath, sheets):
    """Create dictionary with search and replace regex patterns"""

    # @todo: check whether file exists, quit if not
    for sheet in sheets:
        # df = pd.read_excel(config_fpath)
        patterns_df = pd.read_excel(config_fpath, sheet_name=sheet).fillna("")
        patterns = dict(zip(patterns_df.search, patterns_df.replac))
    return patterns


def get_text(fpath):
    """Get all text content from file"""
    with open(fpath, "r") as f:
        return f.read()


def get_backref_values(match, search_pattern, replace_pattern):
    """Get list of backreferences (e.g. $1, $2, etc.) used in replacement pattern"""

    captured_groups = [
        match.group(i) for i in range(1, search_pattern.groups + 1)
    ]  # list of strings

    if len(captured_groups) != 0:  # @dev: needed?
        backreferences = {f"${i}": elem for i, elem in enumerate(captured_groups, 1)}

        return backreferences

    return {}


def recursive_convert_backref_style(replace_pattern):
    """Replaces $<n> style with \\<n> for backreferences in replacement patterns."""

    for match in re.finditer(r"\$(?=\d+)", replace_pattern):
        replace_pattern = re.sub(rf"\{match.group(0)}", "\\\\", replace_pattern)

    return replace_pattern


def log_changes(search_pattern, replace_pattern, text):

    for match in re.finditer(search_pattern, text):

        orig_text = text[:]  # not used
        full_match = match.group(0)
        backreferences = get_backref_values(match, search_pattern, replace_pattern)
        replace_value = replace_pattern[:]

        for k, v in backreferences.items():
            v = v if (v != None) else ""
            replace_value = replace_value.replace(k, v)

        # text = text.replace(full_match, replace_value) # replacing literal strings

        # logging...
        add_to_log(f"{search_pattern=}")  # only interesting for debugging
        add_to_log(f"{full_match=}")  # only interesting for debugging
        add_to_log(f"{replace_pattern=}")  # only interesting for debugging
        add_to_log(f"{backreferences=}")  # only interesting for debugging
        add_to_log(f"{replace_value=}")  # only interesting for debugging
        add_to_log(f"👉 Text matched: '{full_match}'")
        add_to_log(f"👉 Replace with: '{replace_value}'")

        add_to_log(
            "--------------------------------------------------------------------------------"
        )


def run_substitutions(text, patterns, flags=re.DOTALL):
    """Do the substitutions in the text"""

    for k, v in patterns.items():

        if not k or not isinstance(k, str):  # to avoid None and nan
            continue

        search_pattern = re.compile(k, re.MULTILINE | re.DOTALL)
        replace_pattern = rf"{recursive_convert_backref_style(v)}"  # or: r"%s" % v

        orig_text = text[:]
        text = re.sub(search_pattern, replace_pattern, text)

        if orig_text != text:
            log_changes(search_pattern, v, orig_text)

    return text


def create_output_dpath(dpath):
    """Create directory if it doesn't exist"""

    if os.path.isdir(dpath):
        add_to_log(f"Directory {dpath} already exists")
    else:
        try:
            os.mkdir(dpath)  # , access_rights)
        except OSError:
            add_to_log("Error: Creation of directory %s failed" % dpath)
        else:
            add_to_log("Successfully created directory %s " % dpath)


def write_edited_file(fpath, text_content):
    """Create output file and all directories in the path leading to the file"""

    os.makedirs(os.path.dirname(fpath), exist_ok=True)
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(text_content)


# ############# BUSINESS LOGIC ###########################################

if __name__ == "__main__":

    patterns = load_patterns(config_fpath, sheets=["patterns"])  # dictionary

    # @todo: check that input_dpath exists and stop if it doesn't
    create_output_dpath(output_dpath)

    for dirpath, dirs, files in os.walk(input_dpath):

        for fname in files:

            if not fname.endswith(".xml") and not fname.endswith(".html"):
                break

            # paths and names
            add_to_log("")
            add_to_log(
                "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            )

            add_to_log(f"👉 Processing file {fname}... ")
            input_fpath = os.path.join(dirpath, fname)
            d_relpath = os.path.relpath(dirpath, input_dpath)
            output_fpath = os.path.join(output_dpath, d_relpath, fname)

            # processing
            text = get_text(input_fpath)
            text = run_substitutions(
                text, patterns, re.MULTILINE | re.DOTALL
            )  # |re.UNICODE

            ## output
            write_edited_file(output_fpath, text)

            # log
            add_to_log(f"----\nIt took: {datetime.now() - startTime}")
            with open(log_file, "w") as f:
                f.write("\n".join(log))
