#!/bin/bash

for repoName in $( curl -s -H "Authorization: token `cat .github_token`" https://api.github.com/orgs/mojohaus/repos | grep '"name' | grep -e '-wip' | sed 's/    "name": "//g' | sed 's/",.*$//g' )
do
	echo "Deleting $repoName"
	curl -XDELETE -s -H "Authorization: token `cat .github_token`" https://api.github.com/repos/mojohaus/$repoName
done