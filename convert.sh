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
PUSH_TO_GITHUB="yes"

SVN_URL="file:///home/tiste/MOJOHAUS-TO-GIT/SVN-MOJO-WIP"

function getTags {
	tags=""
	for i in `svn ls $SVN_URL/tags | grep $1 | sed 's#/##g'`
	do                
		tags="$tags,$i"
	done
	echo $tags | sed 's/^,//'
}
echo "Let's begin!"
date

for line in `cat repo-infos.csv | grep -v "#"`
do
	projectName=`echo $line|cut -d, -f1`
	trunkPath=`echo $line|cut -d, -f2`
	tagsStartsWith=`echo $line|cut -d, -f3`
	branches=`echo $line|cut -d, -f4|sed 's/|/,/g'`

	echo "################################################"
	echo "################################################"
	echo "# Processing $projectName"
	echo "################################################"
	echo "################################################"
    date

	echo 
	echo "Creating repo $projectName"
	mkdir $projectName
	cd $projectName

	git svn init --trunk $trunkPath $SVN_URL
	
	tagsList=`getTags $tagsStartsWith`
	if [ ! -z "$tagsList" ]; then
		tagsConfig="tags/{$tagsList}:refs/remotes/tags/*"
		echo "Tags specified. Putting '$tagsConfig'"	
		git config svn-remote.svn.tags $tagsConfig
	fi
	
	# Seems a wee touchy. Fortunately that shouldn't be a big issue for us since very
	# few mojos actually have branches. And likely even fewer to really keep.
	if [ ! -z "$branches" ]; then
		# FIXME ? Beware branches cannot contain / with this way
		branchesConfig="branches/{$branches}:refs/remotes/branches/*"
        echo "Branches specified. Putting '$branchesConfig' in the conf"
        git config svn-remote.svn.branches $branchesConfig
	fi

	echo "Fetch data"
	git svn fetch --authors-file=../mojo-committers.list --authors-prog=../authors-prog.sh
	
	echo "Fixing tags"
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
	    echo "Trying to find ancestor for $parent"
	    merge=$( git merge-base "refs/remotes/origin/trunk" $parent || echo "" );
	    if [ "$merge" = "$parent" ]; then
	        target_ref=$parent
	    else
	        echo "tag has diverged: $tag"
	        target_ref="$tag_ref"
	    fi

	    # create an annotated tag based on the last commit in the tag, and delete the "branchy" ref for the tag
	    echo "create the annotated tag $tag_ref"
	    git show -s --pretty='format:%s%n%n%b' "$tag_ref" | \
	    perl -ne 'next if /^git-svn-id:/; $s++, next if /^\s*r\d+\@.*:.*\|/; s/^ // if $s; print' | \
	    env GIT_COMMITTER_NAME="$(  git show -s --pretty='format:%an' "$tag_ref" )" \
	        GIT_COMMITTER_EMAIL="$( git show -s --pretty='format:%ae' "$tag_ref" )" \
	        GIT_COMMITTER_DATE="$(  git show -s --pretty='format:%ad' "$tag_ref" )" \
	        git tag -a -F - "$tag" "$target_ref"

	    git update-ref -d "$tag_ref"
	done

	echo "create local branches out of svn branches"
	git for-each-ref --format='%(refname)' refs/remotes/ | while read branch_ref; do
	    branch=${branch_ref#refs/remotes/}
	    git branch "$branch" "$branch_ref"
	    git update-ref -d "$branch_ref"
	done

	set +e
	echo "remove merged branches"
	git for-each-ref --format='%(refname)' refs/heads | while read branch; do
		echo "Removing $branch... "
	    git rev-parse --quiet --verify "$branch" || continue # make sure it still exists
	    git symbolic-ref HEAD "$branch"
	    git branch -d $( git branch --merged | grep -v '^\*' )
	    echo "OK. Removed $branch"
	done
	set -e
	##########################################################
	# done fixing tags
	##########################################################
	
	# set the origin
	git remote add origin git@github.com:${GITHUB_ORG}/${projectName}.git
	
	if [ $PUSH_TO_GITHUB == "yes" ]; then
		echo "Let's create the GH repo for $projectName and push onto it"
		#create github repo
		curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d '{"name": "'"$projectName"'"}' https://api.github.com/orgs/mojohaus/repos?access_token=$GITHUB_TOKEN

		# note : requires to approve your ssh key: https://github.com/settings/ssh
		#push it all
		git push --all origin
		git push --tags origin
	else
		echo "push to GitHub disabled"
	fi

	echo "Finished processing $projectName"

	cd -
done

date
echo "This is the end."
