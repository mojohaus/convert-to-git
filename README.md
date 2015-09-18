This repo is a Docker image (well, actually its descriptor) designed to make converting
one of the mojos of the Codehaus Project easy for anyone willing to do it.

Please report if you find issues or file pull requests to improve it.

## How to use it?

Simple way: use the public image _batmat/mojohaus-converter_.

The image is design to be run once for each mojo migration.
The resulting migrated Git repository will be created inside the `/newgitrepo` path of the container.

Here's an example command to run to trigger the conversion of the `aspectj-maven-plugin` (note: just an example, [this repo has already been converted and is already accessible](https://github.com/mojohaus/aspectj-maven-plugin))

    d run --rm -v $PWD/newrepo:/newgitrepo \
                -e projectName=aspectj-maven-plugin \
                -e trunkPath=trunk/mojo/aspectj-maven-plugin \
                -e tagsStartsWith=aspectj-maven-plugin- \
                -e branches="" \
          batmat/mojohaus-converter

## Random tips

### Getting users of the svn repo

    $ svn log file:////some/path/MOJOHAUS-TO-GIT/MOJO-WIP | egrep  "^r[0-9]+ \|.*$"  | cut -d'|' -f2 | sort -u > mojo-committers.list


See the file committed in that repo, and please file a PR in the Git svn clone required format :

    svnuser = Firstname Name <dude@domain.com>
