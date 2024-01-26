#!/usr/bin/env bash

# run as:
# bash /path/to/add_file_to_batch.sh.sh -o /path/to/orig/dir -d /path/to/dest/dir -c /path/to/config
# e.g. 
# bash add_file_to_batch.sh -a move -o /home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_es-CR_prepare-files/target -d /home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_es-CR_prepare-files/target_fixed -c $config_yml

while getopts a:c:o:d: flag
do
    case "${flag}" in
        a) action=${OPTARG};;
        c) config=${OPTARG};;
        o) origin_parent_dir=${OPTARG};;
        d) destination_parent_dir=${OPTARG};;
    esac
done

# check that parameters are provided
[[ -z $action ]] || [[ -z $config ]] || [[ -z $origin_parent_dir ]] || [[ -z $destination_parent_dir ]] && echo "
ERROR: Some parameters are missing.

usage: add_file_to_batch.sh [-a ACTION] [-c CONFIG] [-o ORIGIN] [-d DESTINATION]

Puts each file in the specified batch folder

parameters:
  -a ACTION
        action requested: either 'move' or 'copy'
  -c CONFIG
        absolute path to the configuration yaml file that indicates which folder each file belongs to,
  -o ORIGIN
        origin parent directory containing the files to be arranged in folders,
  -d DESTINATION
        destination parent directory where the folders containing the files should be written." && exit

echo "The requested action is: $action files in $origin_parent_dir to their specific batch folder in $destination_parent_dir according to $config"

batches="$(yq -r 'keys | .[]' $config)"

for filepath in $(find $origin_parent_dir -maxdepth 1 -type f -name "*.xml")
do
	# echo "### $filepath ###"
	filename="$(basename -- $filepath)"
	basename=$(echo "$filename" | perl -pe 's/_[^_]+\.xml/.xml/')
	batch=$(FILE=$basename yq '.. | select(. == env(FILE)) | parent | key' $config)
	# [[ "$batch" == "04_QQS_N" ]] && echo "$batch: $filename"

	# if [[ "$batches" == *"$batch"* ]] && [[ "$batch" != "" ]]; then
	if [[ ${batches[@]} =~ $batch ]] && [[ "$batch" != "" ]]; then
	  # echo "$batch:$filename"
	  # echo "cp $filepath $destination_parent_dir/$batch/$filename"
	  mkdir -p "$destination_parent_dir/$batch/"
	  cp "$filepath" "$destination_parent_dir/$batch/$filename"
	  [[ "$action" ==  "move" ]] && rm "$filepath"
	fi
done