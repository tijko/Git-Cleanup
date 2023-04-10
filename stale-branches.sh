#!/usr/bin/env bash

# Pass an argument when running (e.g. ./stale-branches.sh tijko)
# Or Set an environment variable (e.g. export ORG=tijko)
if [[ $# -gt 0 ]]
then
    ORG=$1
fi

if [[ ! $ORG ]]
then
    echo 'Set the environment variable "ORG" or pass as argument (e.g. ./stale-branches.sh tijko)'
    exit 0
fi

echo "Running for $ORG"

WORKSPACE="Workspace"
OUTPUT="$HOME/Stale-Branches.txt"
# XXX Default to 180 days adjust as needed
PERIOD=180
TARGET=$(date -v -"$PERIOD"d "+%Y-%m-%d")
echo "Any branches without activity from $TARGET will be removed"

if [[ -f $OUTPUT ]]
then
    rm $OUTPUT
fi

if [[ ! -d $WORKSPACE ]]
then
    mkdir $WORKSPACE 
fi

cd $WORKSPACE 
# XXX requires the gh-cli tool installed (e.g. brew install gh)
for repository in $(gh repo list $ORG --limit 200 --json name | jq -r .[].name)
do
    # Iterate over cloning each repo.
    echo $repository;
    if [[ ! -d $repository ]]
    then
        git clone git@github.com:$ORG/$repository
    fi
    echo "Project: " $repository >> $OUTPUT 
    cd $repository
    # only list branches beyond 180 of inactivity
    for branch in $(git for-each-ref --sort=-committerdate --format='%(committerdate:format:%Y-%m-%d %I:%M %p) %(refname)' | awk -v DATE=$TARGET '{ if ( index($4, "remotes") != 0 && $1 < DATE ) { print $1":"$4 } }')
    do
        timestamp=$(cut -d':' -f1 <<< $branch);
        branch_name=$(cut -d'/' -f4- <<< $branch);
        if [[ $branch_name != "HEAD" && $branch_name != "main" && $branch_name != "master" && $branch_name != "develop" ]]
        then
            echo "    Time: $timestamp Branch: $branch_name" >> $OUTPUT
            # XXX uncomment to permanently delete branches from remote
            #git push origin -d $branch_name
        fi
    done
    cd -
done
