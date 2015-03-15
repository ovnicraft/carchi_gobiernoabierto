#!/bin/bash

cd /usr/app/irekia5/

# extracted from rvm env --path -- 2.1.2@irekia5
source /usr/local/rvm/environments/ruby-2.1.2@irekia5

if [ -f ~/irekia_secrets.sh ]; then
  source ~/irekia_secrets.sh
fi

rake ogov:check_webtv_video_languages
