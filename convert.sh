#!/bin/bash
set -eou pipefail

# https://github.com/blog/1509-personal-api-tokens
GITHUB_TOKEN=`cat .github_token`
GITHUB_USER=${GITHUB_USER:="batmat"}
PUSH_TO_GITHUB="yes"

for line in `cat repo-infos.csv | grep -v "#"`
do
	projectName=`echo $line|cut -d, -f1`
	trunkPath=`echo $line|cut -d, -f2`
	tagsStartsWith=`echo $line|cut -d, -f3`
	branches=`echo $line|cut -d, -f4|sed 's/|/,/g'`

	docker run --rm \
	           -v $PWD/newrepos:/newgitrepo \
						 -v $HOME/.ssh:/root/.ssh:ro \
             -e projectName=$projectName \
             -e trunkPath=$trunkPath \
             -e tagsStartsWith=$tagsStartsWith \
             -e branches="$branches" \
						 -e PUSH_TO_GITHUB=yes \
						 -e GITHUB_USER=$GITHUB_USER \
						 -e GITHUB_TOKEN=$GITHUB_TOKEN \
         batmat/mojohaus-converter
done

date
echo "This is the end."
