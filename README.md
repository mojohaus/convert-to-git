This repo is a Docker image (well, actually its descriptor) designed to make converting
one of the mojos of the Codehaus Project easy for anyone willing to do it.

Please report if you find issues or file pull requests to improve it.

## How to use it?

Simple way: use the public image _batmat/mojohaus-converter_.

### Subversion -> Git conversion

This image is designed to be run once for each mojo migration.
The resulting migrated Git repository will be created inside the `/newgitrepo` path of the container.

Here's an example command to run to trigger the conversion of the `aspectj-maven-plugin` (note: just an example, [this repo has already been converted and is already accessible](https://github.com/mojohaus/aspectj-maven-plugin))

    docker run --rm -v $PWD/newrepo:/newgitrepo \
               -e projectName=aspectj-maven-plugin \
               -e trunkPath=trunk/mojo/aspectj-maven-plugin \
               -e tagsStartsWith=aspectj-maven-plugin- \
               -e branches="" \
           batmat/mojohaus-converter

When that execution ends, you will have a local new directory called _/newrepo_ with the migrated svn->git repository inside.

### Conversion + Automatic GitHub repository creation + push

TBD

## Random tips
### Accessing the SVN repo
The SVN repository is accessible in the image under the `/mojohaus-svn-repo` path.
Hence, you can for example list the svn content using the simple following form:

    docker run --rm batmat/mojohaus-converter svn ls file:///mojohaus-svn-repo

### Getting users of the svn repo

    docker run --rm batmat/mojohaus-converter \
           svn log file:///mojohaus-svn-repo | \
             egrep  "^r[0-9]+ \|.*$"  | \
             cut -d'|' -f2 | \
             sort -u


See the file committed in that repo, and please file a PR in the Git svn clone required format :

    svnuser = Firstname Name <dude@domain.com>
