/home/souto/Repos/ACER-PISA-2025-FT/lint-test/lint.sh#!/usr/bin/env bash

srcdir="/home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_common/source"
cd $srcdir
mkdir -p 01_COS_SCI-A_N 02_COS_SCI-B_N 03_COS_SCI-C_N 04_QQS_N 05_QQA_N 06_COS_LDW_N 07_COS_XYZ_N

# preparation (once-off)
# gh repo clone capstanlqc/source-xml-linter
# cd source-xml-linter && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt && deactivate && cd ..
# update .gitignore

# get updates
updates=0
status=$(git pull)

# exit if no updates
[ "$status" == "Already up to date." ] && exit 0

# check that the linting script is there
[[ -d $srcdir/source-xml-linter ]] || exit 0

# activate venv
cd source-xml-linter && source venv/bin/activate && cd $srcdir

# create folder to collect files to lint and linted files
tolint=$srcdir/changed_to_lint
linted=$srcdir/linted_2_wrkflw
[[ -d $tolint ]] || mkdir $tolint
[[ -d $linted ]] || mkdir $linted

# check if files have changed and select them for linting
# for line in "$(md5sum --check --quiet files.md5)"
# do
#     if [[ "$line" == *": FAILED"* ]]
#     then
#         file=$(echo "$line" | cut -d: -f1)
#         echo $file
#         cp $file $tolint
#     fi
# done

# check for updates
for fpath in $(find {01_COS_SCI-A_N,02_COS_SCI-B_N,03_COS_SCI-C_N,04_QQS_N,05_QQA_N,06_COS_LDW_N,07_COS_XYZ_N} -type f -exec echo {} \; 2>/dev/null)
do
    filename=${fpath#"$srcdir/"}
    # old_hash=$(md5sum $fpath | cut -d' ' -f1)
    new_hash="$(md5sum $fpath | cut -c -32)"
    old_hash="$(cat $srcdir/files.md5 | grep $filename | cut -c -32)"
    if [ "$old_hash" != "$new_hash" ]; then
        updates=1
        cp $fpath $tolint
    fi
done

# lint updated files and put them back in their folder
python source-xml-linter/str_subs.py -i $tolint -o $linted -c source-xml-linter/config.xlsx

# overwrite file with linted version
for fpath in $(find $linted -type f)
do
    filename=${fpath#"$linted/"}
    orig_fpath=$srcdir/$(cat $srcdir/files.md5 | grep $filename | cut -d' ' -f3)
    mv $fpath $orig_fpath
    git add $orig_fpath && git commit -m "Linted and signed off updated version of $filename"
done

# push changes
git push

# update hash file if there have been updates
[[ $updates == 1 ]] && find {01_COS_SCI-A_N,02_COS_SCI-B_N,03_COS_SCI-C_N,04_QQS_N,05_QQA_N,06_COS_LDW_N,07_COS_XYZ_N} -type f -exec md5sum {} \; > files.md5

# deactivate venv
deactivate

# clean up the mess
rm -r $tolint
rm -r $linted