#!/bin/bash

cd /usr/app/irekia4/
# extracted from rvm env --path -- 1.8.7@irekia4
source /usr/local/rvm/environments/ruby-1.8.7-p334@irekia4

# must execute every 6 hour
rake _0.8.7_ elasticsearch:import_recently_published RAILS_ENV=production
