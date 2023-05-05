# String substitution

This script looks for patterns or literal strings in the input files and replaces them with the corresponding text.

## Business logic in a nutshell

Provided the following as input: 

- a list of search and replace patterns (in an Excel file)
- a folder containing text-based files (e.g. XML)

For every file, the script will:

- look for every search pattern
- replace it with the replacement pattern
- write an output file in the output folder specified

## Getting started

Clone this repo and change directory to it:

```
gh repo clone capstanlqc/string-substitution
cd string-substitution
```

Install a virtual environment in the root folder of the repo (only once):

```
python -m venv venv
```

Activate the virtual environment (before every time you run the script):

```
source venv/bin/activate
```

Install all dependencies in the virtual environment: 

```
pip install -r requirements.txt
```

Run the code (see below for details): 

```
python str_subs.py \
    -i /path/input/folder \
    -o /path/to_output/folder \
    -c /path/to/config.xlsx
```
<!-- e.g.
python techedit_substitution.py \
    -i $(readlink -f 01_orig) \
    -o $(readlink -f 03_edit_auto/) \
    -c config.xlsx
-->


You may exit the virtual environment when you're done running the code:

```
deactivate
```

## How to run the code

The help will show you what input parameters are needed: 

```
$ python str_subs.py --help

usage: str_subs.py [-h] [-V] [-i INPUT] [-o OUTPUT] [-c CONFIG]

String substitution in XML files

options:
  -h, --help            show this help message and exit
  -V, --version         show program version
  -i INPUT, --input INPUT
                        specify path to the folder containing the files to be processed
  -o OUTPUT, --output OUTPUT
                        specify path to the folder where the processed files should be saved
  -c CONFIG, --config CONFIG
                        specify path to the config file containing patterns etc.
```

A log file will be written in logs with an account of what has been done:

## Backlog

Tentative todo list: 

- Parse XML input file and run the substution only inside the text node (e.g. `<label>`)
- Add timestamp to log filename
- Make it a requirement that argument paths are absolute paths