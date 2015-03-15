#!/bin/bash

cd /usr/app/irekia5/
# extracted from rvm env --path -- 2.1.2@irekia5
source /usr/local/rvm/environments/ruby-2.1.2@irekia5

rake ogov:hide_orphan_videos_in_webtv
