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

Puts each file in the specified batch folder inside the destinatino parent folder.

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
    
    # echo "~~~ $filename ~~~"
    echo "filename=$filename"
    # basename=$(echo "$filename" | perl -pe 's/.xml//')
    # echo "basename=$basename"
    
    batch=$(FILE=$filename yq '.. | select(. == env(FILE)) | parent | key' $config)
    echo "batch=$batch"
    # [[ "$batch" == "04_QQS_N" ]] && echo "$batch: $filename"

    # if [[ "$batches" == *"$batch"* ]] && [[ "$batch" != "" ]]; then
    if [[ ${batches[@]} =~ $batch ]] && [[ "$batch" != "" ]]; then
      # echo "$batch:$filename"
      mkdir -p "$destination_parent_dir/$batch/"
      echo "cp $filepath $destination_parent_dir/$batch/$filename"
      cp "$filepath" "$destination_parent_dir/$batch/$filename"
      [[ "$action" ==    "move" ]] && rm "$filepath"
    fi
    echo "---"
done

log_fname="file_sync_issues.log"
log_fpath=$destination_parent_dir/$log_fname

for batch in $batches
do
		# check if $destination_parent_dir/$batch exists, if not flag it and continue
		files_in_batch=$(yq eval ".$batch[]" "$config")
    for filepath in $(find $destination_parent_dir/$batch -maxdepth 1 -type f)
    do
        filename="$(basename -- $filepath)"
        if ! printf "%s\n" "${files_in_batch[@]}" | grep -qx "$filename"; then
        			batch_in_config=$(grep $filename $destination_parent_dir/files.tsv | cut -d$'\t' -f1)
              echo "Discrepancy: file '$filename': has batch $batch in repo, but batch '$batch_in_config' in config" >> $log_fpath
        fi
    done
done

sed -i '/gitkeep/d' $log_fpath
sed -i '/zz.txt/d' $log_fpath
sed -i '/.html/d' $log_fpath
cat $log_fpath | sort | uniq > $log_fpath