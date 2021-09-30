#!/bin/sh

if [ $SKIP_HOOK ] ; then
  exit 0
fi

eslint="/usr/bin/eslint"
files=$(git diff --cached --name-only --diff-filter=d | grep -E '\.mjs$|\.js$')

if [[ $files = "" ]] ; then
  exit 0
fi

exit_status=0

for file in ${files}; do
  git show :$file | $eslint $file
  if [[ $? != 0 ]] ; then
    exit_status=1
  fi
done;

if [[ $exit_status != 0 ]] ; then
  echo "ESLint failed, git commit aborted!"
  exit $exit_status
fi
