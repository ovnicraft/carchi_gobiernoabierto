#!/bin/bash

cd /usr/app/irekia4/
# extracted from rvm env --path -- 1.8.7@irekia4
source /usr/local/rvm/environments/ruby-1.8.7-p334@irekia4

rake _0.8.7_ ogov:tweet_pending_issues RAILS_ENV=production
