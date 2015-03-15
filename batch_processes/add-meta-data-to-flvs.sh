# Adds meta data to flv files so that it is possible to scroll across the pseudostreaming timeline
#!/bin/bash

if [ -f /tmp/add_meta_running_lock ]
then
    exit
fi

touch /tmp/add_meta_running_lock

if [ $# -ne 1 ]
then
  echo "Usage: add-meta.sh filename"
  exit 2
fi

if /usr/bin/flvmeta $1 |grep hasMetadata
then
  echo "metadata present"
else
  echo "adding metadata"
  /usr/bin/flvmeta $1 $1s
  # mv $1 /tmp
  mv -f $1s $1
fi

rm /tmp/add_meta_running_lock
