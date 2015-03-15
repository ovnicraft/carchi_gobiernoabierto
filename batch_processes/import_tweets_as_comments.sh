#!/bin/bash

cd /usr/app/irekia5/

# rvm env --path -- 2.1.2@irekia5
source /usr/local/rvm/environments/ruby-2.1.2@irekia5

if [ -f ~/irekia_secrets.sh ]; then
  source ~/irekia_secrets.sh
fi

rake external:import_tweets_as_comments  > /usr/app/irekia5/log/error.log
