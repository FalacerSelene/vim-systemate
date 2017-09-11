#! /usr/bin/env bash

for diff in test/output/*.diff ; do
	if [[ "${diff}" == 'tests/output/*.diff' ]] ; then
		continue
	else
		echo "Diff file ${diff}:"
		cat "${diff}"
		echo
	fi
done
