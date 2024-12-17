#!/usr/bin/env bash

# run as:
# bash /path/to/check_files_sync.sh -o /path/to/orig/dir -d /path/to/dest/dir -c /path/to/config.yaml
# e.g. 
# bash check_files_sync.sh -a move -o /home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_es-CR_prepare-files/target -d /home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_es-CR_prepare-files/target_fixed -c $config_yml

while getopts a:c:o:d: flag
do
    case "${flag}" in
        c) config=${OPTARG};;
        d) directory=${OPTARG};;
    esac
done

# check that parameters are provided
[[ -z $config ]] || [[ -z $directory ]] && echo "
ERROR: Some parameters are missing.

usage: check_files_sync.sh [-c CONFIG] [-d DIRECTORY]

Looks for mismatches between the batches-units config file and the folders/files in the common repository.

parameters:
    -c CONFIG
                absolute path to the configuration yaml file that indicates which folder each file belongs to,
    -d DIRECTORY
                directory containing the batch folders containing unit files." && exit

timestamp=$(date +"%Y%m%d")

# batches according to the config
batches="$(yq -r 'keys | .[]' $config)"

log_fname="file_sync_${timestamp}.log"
tmp_fname="file_sync.tmp"
log_fpath=$directory/$log_fname
tmp_fpath=$directory/$tmp_fname
touch $log_fpath $tmp_fpath
echo "logging to $log_fpath"
echo ""

# check for batch allocation discrepancies
for batch in $batches
do
	# check if $directory/$batch exists, if not flag it and continue
    [[ -d $directory/$batch ]] || continue

    # get files in batch according to the config
	# files_in_batch=$(yq eval ".$batch[]" "$config")
    mapfile -t files_in_batch < <(yq eval ".$batch[]" "$config")

    for fname in "${files_in_batch[@]}"
    do
        # echo "ls -1 $directory/$batch | grep $fname | wc -l"
        

        # count=$(find $directory/$batch -name "$fname" | wc -l)
        # echo "ls -1 $directory/$batch | grep $fname | wc -l"
        count=$(ls -1 "$directory/$batch" | grep "$fname" | wc -l)
        if [[ "$count" -eq "0" ]]; then
            echo "Not found in repo: file $fname NOT found in $directory/$batch" >> $log_fpath
        fi
    done

    for filepath in $(find $directory/$batch -maxdepth 1 -type f)
    do
        filename="$(basename -- $filepath)"
        [[ "$filename" == "zz.txt" ]] && continue
        [[ "$filename" == ".gitkeep" ]] && continue

        # check for batch folder mismatches
        if ! printf "%s\n" "${files_in_batch[@]}" | grep -qx "$filename"; then
            batch_in_config=$(grep $filename $directory/files.tsv | cut -d$'\t' -f1)
            # echo "Discrepancy: file '$filename': has batch $batch in repo, but batch '$batch_in_config' in config"
            echo "Discrepancy: file '$filename': has batch $batch in repo, but batch '$batch_in_config' in config" >> $log_fpath
        fi

        # check for dropped files
        if ! grep -q $filename $config
        then
            # echo "File $filename NOT found in config."
            echo "Not found in config: file $filename" >> $log_fpath
        fi        
    done
done


# sed -i '/gitkeep/d' $log_fpath
# sed -i '/zz.txt/d' $log_fpath
# sed -i '/.html/d' $log_fpath
cat $log_fpath | sort | uniq > $tmp_fpath
cat $tmp_fpath > $log_fpath

echo "--- RESULTS ---"
cat $log_fpath
rm $tmp_fpath