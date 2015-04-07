This repo is a WIP for tools around migrating the Codehaus MOJO from Codehaus infrastructure to GitHub.

= Getting users of the svn repo
svn log file:////some/path/MOJOHAUS-TO-GIT/MOJO-WIP | egrep  "^r[0-9]+ \|.*$"  | cut -d'|' -f2 | sort -u > mojo-committers.list


See the file committed in that repo, and please a PR in the Git svn clone required format :

svnuser = Firstname Name <dude@domain.com>

