#!/usr/bin/env bash

# call as:
# bash /path/to/source-xml-linter/main.sh -p /path/to/pisa_2025ms_translation_common

while getopts "p:" option; do
  case "${option}" in
    p)
      pisa25ms_common_repo=${OPTARG}
      ;;
    *)
      echo "Usage: $0 -p /path/to/pisa_2025ms_translation_common"
      exit 1
      ;;
  esac
done

app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "app_root=$app_root"
# app_root="/home/souto/~/Repos/capstanlqc/source-xml-linter"

# pisa25ms_common_repo="/media/souto/SD1TB400MBPS/Repos/ACER-PISA-2025-MS/pisa_2025ms_translation_common"
# move to .env

source=$pisa25ms_common_repo/source
echo "source=$source"

tolint_new=$source/tolint_new
tolint_trend=$source/tolint_trend
tolint_xyz=$source/tolint_xyz
linted=$source/linted

files_tsv=$source/files.tsv
files_yml=$source/files.yaml

# this activates the venv only in the scope of this script
source $app_root/venv/bin/activate
venv_python=$(which python)
#venv_python="$app_root/venv/bin/python"

echo $venv_python

# this assumes that files.tsv is up to date
$venv_python $app_root/tsv2yml.py -i $source/files.tsv -o $source/files.yaml

dom="new"
$venv_python $app_root/str_subs.py -i $source/tolint_${dom} -o $source/linted -c $app_root/config_${dom}.xlsx

dom="trend"
# $venv_python $app_root/str_subs.py -i $source/tolint_${dom} -o $source/linted -c $app_root/config_${dom}.xlsx

dom="xyz"
# $venv_python $app_root/str_subs.py -i $source/tolint_${dom} -o $source/linted -c $app_root/config_${dom}.xlsx

bash $app_root/add_file_to_batch.sh -a copy -c $source/files.yaml -o $source/linted -d $source

# check sync
# for file in $(find 23_COSP_MAT-A_T -name "*.xml" | cut -d"/" -f2); do if ! grep -q "$file" files.tsv; then echo "$file not found"; fi; done
bash check_files_sync.sh -d $source -c $source/files.yaml