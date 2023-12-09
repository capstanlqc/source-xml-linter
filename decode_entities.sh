#!/usr/bin/env bash

# run as:
# bash /path/to/decode_entities.sh -r /path/to/repo -d relative/path/to/directory -c /path/to/config
# e.g.
# bash $app/decode_entities.sh -r /home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_common -d source/tolint_trend -c /home/souto/Repos/ACER-PISA-2025-FT/source-xml-linter/entities.json

# to run from anywhere, do (requires parsing argument)
# bash /path/to/decode_entities.sh --config /path/to/entities.json

while getopts r:d:c: flag
do
    case "${flag}" in
        r) repo=${OPTARG};;
        d) directory=${OPTARG};;
		c) config=${OPTARG};;
    esac
done

# repo="/home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_common"
# mapping="/home/souto/Repos/ACER-PISA-2025-FT/source-xml-linter/entities.json"
files="$repo/$directory"
mapping="$config"

cd $repo
# git pull # uncomment for .git

cd $files

# escaped XML valid entities (replace with unescaped entity), e.g. &amp;quot; -> &quot;
for entity in $(grep -Poh '&amp;(lt|gt|quot|amp);' $files/*.xml | sort | uniq)
do
	echo "Found entity '$entity' in..."
	grep -l $entity $files/*.xml | sort | uniq
	unescaped="${entity/"&amp;"/"&"}"
	echo "Turn into '$unescaped'"
	# grep -Po --color $entity $files/*.xml
	echo "1. Replace named entity '$entity' with character '$unescaped'"
	# perl -i -pe 's/"$entity"/"$unescaped"/g' $files/*.xml
done

# escaped numeric entities (e.g. &amp;#x265E; -> &#x265E;) # the mapping might not have the character, e.g. ♞
for entity in $(grep -R -Poh "&amp;#x[0-9A-Z]+;" . | sort | uniq)
do
	echo "Found entity '$entity' in..."
	grep -l $entity $files/*.xml | sort | uniq
	unescaped="${entity/"&amp;"/"&"}"
	# grep -Po --color $entity $files/*.xml
	# char="$(jq --raw-output --arg VAR $unescaped '.[$VAR].characters' $mapping)"
	echo "2. Replace named entity '$entity' with character '$unescaped'"
	perl -i -pe "s/$entity/$unescaped/g" $files/*.xml
done

# named entities to unicode (e.g. &nbsp; ->  )
# for entity in $(jq -r 'keys[]' $mapping)
for entity in $(grep -Poh '&(?!lt|gt|quot|amp)[A-Za-z]+[0-9]*;' $files/*.xml | sort | uniq)
do
	echo "Found entity '$entity' in..."
	grep -Pl $entity $files/*.xml | sort | uniq
	# grep -Po --color $entity $files/*.xml
	char="$(jq --raw-output --arg VAR $entity '.[$VAR].characters' $mapping)"
	echo "3. Replace named entity '$entity' with character '$char'"
	perl -i -pe "s/$entity/$char/g" $files/*.xml
done

# for double escapes  (e.g. &amp;nbsp; ->  )
# for entity in $(jq -r 'keys[]' $mapping)
for entity in $(grep -Poh '&amp;(?!lt|gt|quot|amp)[A-Za-z]+[0-9]*;' $files/*.xml | sort | uniq)
do
	echo "Found entity '$entity' in..."
	grep -Pl $entity $files/*.xml | sort | uniq
	unescaped="${entity/"&amp;"/"&"}"	
	# grep -Po --color $entity $files/*.xml
	char="$(jq --raw-output --arg VAR $unescaped '.[$VAR].characters' $mapping)"
	echo "4. Replace named entity '$entity' with character '$char'"
	perl -i -pe "s/$entity/$char/g" $files/*.xml
done



# sleep 10
# git add . && git commit -m "Replaced named entities with Unicode plain characters"
# git push

# &amp;deg; -> °
# &amp;euro; -> €
# &amp;mdash; -> —
# &amp;mu; -> μ
# &amp;nbsp; ->  
# &amp;ndash; -> –

# &amp;quot; -> &quot;
# &amp;lt; -> &lt;

# grep -Poh '&(?!lt|gt|quot|amp)[A-Za-z]+[0-9]*;' source/batch1/*.xml | sort | uniq
# &divide; -> ÷
# &mdash; -> —




echo "done"