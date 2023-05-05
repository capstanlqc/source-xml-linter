# -*- coding: utf-8 -*-
import sys, os
from datetime import datetime
startTime = datetime.now()

# import regex as re
import re
import argparse
#from types import new_class
import pandas as pd
#import markdown
#import enchant
#import string
from nltk.tokenize import word_tokenize
#from nltk.tokenize import sent_tokenize
from bs4 import BeautifulSoup
#import pprint
import subprocess
import platform
import requests
from urllib3.exceptions import InsecureRequestWarning # to allow insecure fetching of the rendtry file


# install dependencies
# pip install pandas requests pyenchant bs4 argparse nltk html5lib openpyxl
# >>> nltk.download('punkt')

log = []
def add_to_log(line):
    log.append(line)

# ############# PROGRAM DESCRIPTION ###########################################

text = "Codility -- Mask or strip code and placeholders"

# initialize arg parser with a description
parser = argparse.ArgumentParser(description=text)
parser.add_argument("-V", "--version", help="show program version",
                    action="store_true")
#parser.add_argument("-p", "--params", help="specify path to list of patterns")
parser.add_argument(
    "-i", "--input", help="specify path to the file to be processed")

# read arguments from the command cur_str
args = parser.parse_args()

"""
# versioning
# 1.0.1 - 202010901 - Adding rentry fetch utility
"""
# check for -V or --version
version_text = "Codility Task Description Masker 1.0.1"
if args.version:
    print(version_text)
    sys.exit()
#if args.params:
    #print("Using patterns from file %s" % args.params)
if args.input:
    pass #print("Processing cur_strs from %s" % args.input)

if args.input: # and args.params:
    #config_fpath = args.params.rstrip('/')
    file_dpath = args.input.rstrip('/')
else:
    print("Argument -i not found.")
    sys.exit()

path, file = os.path.split(file_dpath)
print(f"{path}")

#output_path = re.sub('target\\\\files', 'masked', path)
output_path = path.replace('target', 'masked')


    
output_file = os.path.join(output_path, file)
parent_dir = os.path.dirname(os.path.realpath(__file__))
patterns_fpath = os.path.join(parent_dir, 'patterns.tsv')
config_fpath = os.path.join(parent_dir, 'config.xlsx') #.replace('C:/', '/mnt/c/')
log_file = os.path.join(parent_dir, 'log.txt') #.replace('C:/', '/mnt/c/')
# script_dpath = os.path.realpath(__file__)


# ############# FUNCTIONS ###########################################


def fetch_file_content(url):
    ''' Fetches known words file from rentry
    >>> requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
    >>> r = requests.get(url, verify=False)
    >>> print(r.status_code)
    200
    '''
    requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)
    try:
        r = requests.get(url, verify=False)
        return r.content
    except requests.exceptions.ConnectionError:
        r.status_code = "Connection refused"
        return None

    # fpath = os.path.join(parent_dir, 'known_words.md')
    # open(fpath, 'wb').write(r.content)
    


def load_patterns(config_fpath, sheets):

    # check whether file exists, quit if not

    for sheet in sheets:
        #df = pd.read_excel(config_fpath)
        patterns_df = pd.read_excel(config_fpath, sheet_name=sheet).fillna('')
        patterns = dict(zip(patterns_df.search, patterns_df.replac))  # OR
    return patterns


def load_column_as_list(fpath, sheet, col_idx):
    df = pd.read_excel(fpath, sheet_name=sheet, header=None).fillna('')
    return list(df.loc[:, 0])


def get_text(fpath):
    with open(fpath, 'r') as f:
        return f.read()


def normalize_quotes(text):
    text = re.sub(r"([A-Za-z]+)'([a-z]+)", r"\1’\2", text) # quotes used as apos: don't -> don’t
    text = text.replace("''", '"')
    #text = re.sub(r"\b'(\w[^']+)\w'\b", r'""\1', text)
    #text = text.replace("'", '"') # because text inspector handles double quotes well
    return text


def strip_str(str):
    str = str.strip()
    while re.match(r'(["`]).+?\1', str) or re.match(r"(').+?\1", str):
        str = re.sub(r'(\w)\.(\w)', r'\1 \2', str)
        #####str = re.sub(r'\*\*([^*\n]+)\*\*', r'\1', str) # => moved to a rule
        str = str.lstrip('`').rstrip('`')
        str = str.lstrip('"').rstrip('"')
        str = str.lstrip("'").rstrip("'")
        #str = re.sub(r'^\{+([^{}]+)\}+$', r'\1', str)
        #str = re.sub(r'^\(+([^()]+)\)+$', r'\1', str)
        #str = re.sub(r'^\[+([^[\]]+)\]+$', r'\1', str) 
    return str


def split_var_name(str):
    return re.sub(r'([a-z])([A-Z])', r'\1 \2', str).replace('-', ' ').replace('_', ' ').replace('/', ' ')
    # use nltk


def remove_code(str):
    str = re.sub(r'^(POST|GET) .+$', 'naw2', str)
    while re.findall(r'^`(?:export|public|private|class) (.+)', str):
        str = re.sub(r'^`(?:export|public|private|class) (.+)', r'`\1', str)
    str = re.sub(r'(?<=\w)<\w[^<>]+>', 'naw2', str) # code tab
    str = str.strip('()')
    return str


def is_word(cur_str):
    return True


def is_linebreak(str):
    return re.match(r'[\r\n]', str)


def is_alphanum(str):
    return re.match(r'\w+', str)


def get_backref_values(match, search_pattern, replace_pattern):

    captured_groups = [match.group(i) for i in range(1, search_pattern.groups+1)] # list of strings

    if len(captured_groups) != 0: # @dev: needed?
                   
        print(f"{captured_groups=}")

        backreferences = {f"${i}": elem for i, elem in enumerate(captured_groups, 1)}

        # number = int(ref.lstrip('$'))-1
        return backreferences

    return {}


def process_text(text, patterns, flags=re.DOTALL):

    
    for k, v in patterns.items():
        print("=============================================================================================")
        
        add_to_log('>------------------')
        if k and isinstance(k, str):  # to avoid None and nan
            add_to_log(f"Find {k}")
            print(f"Find {k}")
            print(f"replace with {v}")
            search_pattern = re.compile(k, re.MULTILINE|re.DOTALL)
            replace_pattern = v
            print(f"{search_pattern=}")


            for match in re.finditer(search_pattern, text): #, overlapped=True):
                
                print("---------------------------------------------------------------------------------------------")
                full_match = match.group(0)
                print(f"{full_match=}")


                add_to_log(f"Replace '{k}' with '{v}'")
                
                # backreferences = re.findall(r'\$\d+', replace_pattern)

                        
                print(f"{search_pattern=}")
                print(f"{replace_pattern=}")



                backreferences = get_backref_values(match, search_pattern, replace_pattern)
                print(f"{backreferences=}")
                print(f"{replace_pattern=}")
                replace_value = replace_pattern[:]

                for k,v in backreferences.items():
                    replace_value = replace_value.replace(k, v)

                print(f"Will replace '{full_match}' with '{replace_value}'")
                text = text.replace(full_match, replace_value) # replacing literal strings
        
    return text


def create_output_dpath(dpath):
    """Create directory if it doesn't exist"""
    #access_rights = 0o755
    if os.path.isdir(dpath):
        print(f"Directory {dpath} already exists")
    else:
        try:
            os.mkdir(dpath) # , access_rights)
        except OSError:
            print("Creation of directory %s failed" % dpath)
        else:
            print("Successfully created directory %s " % dpath)

def write_edited_file(fpath, text_content):
    """Create output file and all directories in its path"""
    os.makedirs(os.path.dirname(fpath), exist_ok=True)
    with open(fpath, "w", encoding='utf-8') as f:
        f.write(text_content)



# ############# BUSINESS LOGIC ###########################################

if __name__ == "__main__":

    patterns =  load_patterns(config_fpath, sheets=['patterns']) # dictionary

    # input = orig folder
    # output = edit folder
    input_dpath = "/home/souto/Sync/PISA25/SourceSignoff/Done2Diff/01_orig/" # 05_COS_SCI3_N/"
    output_dpath = "/home/souto/Sync/PISA25/SourceSignoff/Done2Diff/03_edit_auto/" # 05_COS_SCI3_N/"

    # check that input_dpath exists and stop if it doesn't 
    #   # check that input_dpath exists and create it if it doesn't

    create_output_dpath(output_dpath)
 
    for dirpath, dirs, files in os.walk(input_dpath):

        for fname in files:

            # paths and names
            print()
            print()
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")

            print(f"Processing {fname}... ") # @todo: add to log
            input_fpath = os.path.join(dirpath, fname)
            d_relpath = os.path.relpath(dirpath, input_dpath)
            output_fpath = os.path.join(output_dpath, d_relpath, fname)

            # processing
            text = get_text(input_fpath)
            text = process_text(text, patterns, re.MULTILINE|re.DOTALL) # |re.UNICODE
             
            add_to_log(f'----\nIt took: {datetime.now() - startTime}')

            ## OUTPUT
            # create_edited_file(output_fpath, text)

            write_edited_file(output_fpath, text)

            with open(log_file, 'w') as f:
                f.write('\n'.join(log))

    """
    print()

    text = "others?"
    search = "\?"
    # replac = "Jess asks, ‘Do some colours of food attract ants more quickly than others?’"
    replac = "@"

    regex = re.compile(search, re.MULTILINE|re.DOTALL)
    # text = text.replace(search, replac)
    for match in re.finditer(regex, text):
        full_match = match.group(0)
        print(full_match)
        # do stuff with captured groups (if any)
        # text = re.sub(full_match, replac, text)
        text = text.replace(full_match, replac)
        
    print(text)
    """ 