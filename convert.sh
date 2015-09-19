#!/bin/bash
set -eou pipefail

# Reused http://blog.sonatype.com/2011/04/goodbye-svn-hello-git/#.VUPexCftmkq
# and a mix of many other ones and past experience

GITHUB_USER=batmat
# https://github.com/blog/1509-personal-api-tokens
GITHUB_TOKEN=`cat .github_token`
# http://fabian-kostadinov.github.io/2015/01/16/how-to-find-a-github-team-id/
GITHUB_TEAM_ID=1353638
GITHUB_ORG=mojohaus
PUSH_TO_GITHUB="yes"

for line in `cat repo-infos.csv | grep -v "#"`
do
	projectName=`echo $line|cut -d, -f1`
	trunkPath=`echo $line|cut -d, -f2`
	tagsStartsWith=`echo $line|cut -d, -f3`
	branches=`echo $line|cut -d, -f4|sed 's/|/,/g'`

	docker run --rm -v $PWD/newrepos:/newgitrepo \
             -e projectName=$projectName \
             -e trunkPath=$trunkPath \
             -e tagsStartsWith=$tagsStartsWith \
             -e branches="$branches" \
         batmat/mojohaus-converter
done

date
echo "This is the end."
