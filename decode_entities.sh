#!/usr/bin/env bash

# cd to the folder contianing this script and entities.json, then do
# bash decode_entities.sh

# to run from anywhere, do (requires parsing argument)
# bash /path/to/decode_entities.sh --config /path/to/entities.json

repo="/home/souto/Repos/ACER-PISA-2025-FT/pisa_2025ft_translation_common_TESTS"
files="$repo/source/batch1"
mapping="/home/souto/Repos/ACER-PISA-2025-FT/source-xml-linter/entities.json"

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
	echo "Replace named entity '$entity' with character '$unescaped'"
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
	echo "Replace named entity '$entity' with character '$unescaped'"
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
	echo "Replace named entity '$entity' with character '$char'"
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
	echo "Replace named entity '$entity' with character '$char'"
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