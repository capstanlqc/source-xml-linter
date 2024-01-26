#!/usr/bin/env bash

source_dir="/home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_common/source"
root="$source_dir/linted_trend"
config="$source_dir/files_trend.yaml"

# cd $root

batches="$(yq -r 'keys | .[]' $config)"

for filepath in $(find $root -type f -name "*.xml")
do
	# echo "### $filepath ###"
	filename="$(basename -- $filepath)"
	batch=$(FILE=$filename yq '.. | select(. == env(FILE)) | parent | key' $config)
	# [[ "$batch" == "04_QQS_N" ]] && echo "$batch: $filename"

	# if [[ "$batches" == *"$batch"* ]] && [[ "$batch" != "" ]]; then
	if [[ ${batches[@]} =~ $batch ]] && [[ "$batch" != "" ]]; then
	  echo "$batch;$filename"
	  cp $filepath $source_dir/$batch
	fi
done
