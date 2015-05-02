#!/bin/bash

# Reused http://blog.sonatype.com/2011/04/goodbye-svn-hello-git/#.VUPexCftmkq 
# and a mix of many other ones and past experience

set -eou pipefail

GITHUB_USER=batmat
# https://github.com/blog/1509-personal-api-tokens
GITHUB_TOKEN=`cat .github_token`
# http://fabian-kostadinov.github.io/2015/01/16/how-to-find-a-github-team-id/
GITHUB_TEAM_ID=1353638
GITHUB_ORG=mojohaus

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
	git svn fetch --authors-file=../mojo-committers.list --authors-prog=../authors-prog.sh
	
	set +e
	##########################################################
	# fix the tags, from: https://github.com/nothingmuch/git-svn-abandon
	# from http://blog.sonatype.com/2011/04/goodbye-svn-hello-git/#.VUPexCftmkq :-)
	##########################################################
	# create annotated tags out of svn tags
	git for-each-ref --format='%(refname)' refs/remotes/tags/* | while read tag_ref; do
	    tag=${tag_ref#refs/remotes/tags/}
	    tree=$( git rev-parse "$tag_ref": )

	    # find the oldest ancestor for which the tree is the same
	    parent_ref="$tag_ref";
	    while [ $( git rev-parse --quiet --verify "$parent_ref"^: ) = "$tree" ]; do
	        parent_ref="$parent_ref"^
	    done
	    parent=$( git rev-parse "$parent_ref" );

	    # if this ancestor is in trunk then we can just tag it
	    # otherwise the tag has diverged from trunk and it's actually more like a
	    # branch than a tag
	    merge=$( git merge-base "refs/remotes/trunk" $parent );
	    if [ "$merge" = "$parent" ]; then
	        target_ref=$parent
	    else
	        echo "tag has diverged: $tag"
	        target_ref="$tag_ref"
	    fi

	    # create an annotated tag based on the last commit in the tag, and delete the "branchy" ref for the tag
	    git show -s --pretty='format:%s%n%n%b' "$tag_ref" | \
	    perl -ne 'next if /^git-svn-id:/; $s++, next if /^\s*r\d+\@.*:.*\|/; s/^ // if $s; print' | \
	    env GIT_COMMITTER_NAME="$(  git show -s --pretty='format:%an' "$tag_ref" )" \
	        GIT_COMMITTER_EMAIL="$( git show -s --pretty='format:%ae' "$tag_ref" )" \
	        GIT_COMMITTER_DATE="$(  git show -s --pretty='format:%ad' "$tag_ref" )" \
	        git tag -a -F - "$tag" "$target_ref"

	    git update-ref -d "$tag_ref"
	done

	# create local branches out of svn branches
	git for-each-ref --format='%(refname)' refs/remotes/ | while read branch_ref; do
	    branch=${branch_ref#refs/remotes/}
	    git branch "$branch" "$branch_ref"
	    git update-ref -d "$branch_ref"
	done

	# remove merged branches
	git for-each-ref --format='%(refname)' refs/heads | while read branch; do
	    git rev-parse --quiet --verify "$branch" || continue # make sure it still exists
	    git symbolic-ref HEAD "$branch"
	    git branch -d $( git branch --merged | grep -v '^\*' )
	done
	##########################################################
	# done fixing tags
	##########################################################
	
	#create github repo
	curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d '{"name": "'"$projectName-wip"'"}' https://api.github.com/orgs/mojohaus/repos?access_token=$GITHUB_TOKEN

	# set the origin
	git remote add origin git@github.com:${GITHUB_ORG}/${projectName}-wip.git
	#push it all
	git push --tags origin master

	set -e
	

	cd -
done
