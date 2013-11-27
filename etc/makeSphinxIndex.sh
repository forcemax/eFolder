#!/bin/bash

RUNFILE="/tmp/sphinxindexing"
SPHINX_INDEXER="/opt/sphinx/bin/indexer"
SPHINX_CONF="/opt/sphinx/etc/sphinx.conf"

if [[ "$1" != "all"  && "$1" != "delta" ]]; then
	exit 1
fi

if [ "$1" == "all" ]; then
	while [ -e $RUNFILE ]; do
		sleep 5
	done
fi

if [ "$1" == "delta" ]; then
	if [ -e $RUNFILE ]; then
		exit 1
	fi
fi

touch $RUNFILE

if [ "$1" == "all" ]; then
	rm -f "/tmp/lastCrawlRun.time"
	perl FILE_crawl.pl
	$SPHINX_INDEXER --config $SPHINX_CONF --all --rotate
fi

if [ "$1" == "delta" ]; then
	$SPHINX_INDEXER --config $SPHINX_CONF delta --rotate
fi

rm -f $RUNFILE

exit 0

