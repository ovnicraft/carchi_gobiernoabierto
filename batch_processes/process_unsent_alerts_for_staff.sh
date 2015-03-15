#!/bin/bash

cd /usr/app/irekia5/

# Extracted from rvm env --path -- 2.1.2@irekia5
source /usr/local/rvm/environments/ruby-2.1.2@irekia5

rake ogov:process_unsent_alerts_for_staff
