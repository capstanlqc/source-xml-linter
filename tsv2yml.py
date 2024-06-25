#!/usr/bin/env python3

import os, sys
import pandas as pd
import argparse
# import yaml
import ruamel.yaml

# ############# PROGRAM DESCRIPTION ###########################################

# run as:
# python tsv2yml.py -i $config_tsv_path -o $config_yml_path

text = "Converts two-column TSV file to YAML format"

# initialize arg parser with a description
parser = argparse.ArgumentParser(description=text)
parser.add_argument("-V", "--version", help="show program version",
                    action="store_true")
#parser.add_argument("-p", "--params", help="specify path to list of patterns")
parser.add_argument(
    "-i", "--input", help="specify path to the input file that must be read")
parser.add_argument(
    "-o", "--output", help="specify path to the output file that will be written")

# read arguments from the command cur_str
args = parser.parse_args()

# check for -V or --version
version_text = "tsv2yml 1.0"
if args.version:
    print(version_text)
    sys.exit()

if args.input and args.output:
    input_fpath = args.input.rstrip('/')
    output_fpath = args.output.rstrip('/')
else:
    print("Some required argument not found. Run this script with `--help` for details.")
    sys.exit()

# ############# BUSINESS LOGIC ###########################################

# the TSV input file must have column headers: batch, unit

df = pd.read_csv(input_fpath, sep="\t")

headers = df.columns.values.tolist()
try:
    assert headers == ['batch', 'unit']
except AssertionError as e:
    print("The headers of the input TSV are not 'batch' and 'unit' separated by a tabulator as expected.")
    sys.exit()


config_dict = {batch: df.query(f"batch == '{batch}'")['unit'].tolist() for batch in df[df.columns[0]].unique()}

with open(output_fpath, 'w') as file:
    yaml = ruamel.yaml.YAML()
    yaml.indent(sequence=4, offset=2)
    yaml.dump(config_dict, file)

print(f"YAML config file written to {output_fpath}.")