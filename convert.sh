#!/bin/bash
set -eou pipefail

SVN_URL="file:///home/tiste/MOJOHAUS-TO-GIT/SVN-MOJO-WIP"

function getTags {
	tags=""
	for i in `svn ls $SVN_URL/tags | grep $1 | sed 's#/##g'`
	do                
		tags="$tags,$i"
	done
	echo $tags | sed 's/^,//'
}

for line in `cat repo-infos.csv | grep -v "#"`
do
	projectName=`echo $line|cut -d, -f1`
	tagsStartsWith=`echo $line|cut -d, -f2`

	tagsList=`getTags $tagsStartsWith`

	echo "Creating repo $projectName"
	mkdir $projectName
	cd $projectName

	echo $SVN_URL
	git svn init --trunk trunk/mojo/$projectName $SVN_URL
	git config svn-remote.svn.tags "tags/{$tagsList}:refs/remotes/tags/*"

	echo "Fetch data"
	git svn fetch --authors-file=../mojo-committers.list
done
