#!/usr/bin/ruby
#
# Import de log de Wowza en el cdb.
# depende del view inverse/md5s con map:
#
# function(doc) {
#  emit(doc.md5, null);
# }
#
# ej. de uso:
#   cp /usr/local/WowzaMediaServerPro-1.7.2/logs/wowzamediaserverpro_access.log w.log; 
#   ruby import-wlog.rb; 
#   ruby /home/ogov/stream_counter_cdb.rb
#

require 'rubygems'
require 'couchrest'
require 'cgi'
require 'digest/md5'
require 'pp'

# log fields:
Cx_severity  = 0  #
Cx_category  = 1  #
Cx_event     = 2  #
Cdate        = 3  #
Ctime        = 4  #
Cc_client_id = 5  #
Cc_ip        = 6  #
Cc_port      = 7  # 
Ccs_bytes    = 8 
Csc_bytes    = 9  
Cx_duration  = 10  
Cx_sname     = 11
Cx_stream_id = 12 
Csc_stream_bytes = 13 
Ccs_stream_bytes = 14

Cx_file_size     = 15
Cx_file_length   = 16

Cx_ctx     = 17
Cx_comment = 18



sl=CouchRest.database('http://localhost:5984/wlog3')
onusers = 0
logfile = File.new("w.log")
logfile.each do |logline| 
  if logline[0] == 35
    ; # puts 'comment:'
  else 
    logdl = logline.split(/\t/)
    md5 = Digest::MD5.hexdigest(logline)

    previ=sl.view('inverse/md5s', { :key => md5 })
    alreadyin = (previ['rows'].size > 0)
    if alreadyin 
      # puts '- already imported, next ...'
    else
      puts md5 + " "+ logdl[Cdate]+' '+logdl[Ctime] + " : " + logdl[Cc_client_id]  + ":"+ logdl[Cx_event] + ', ' + logdl[Csc_bytes] 
      sl.save_doc( {'host' => 'bideoak3',
                   'type' => 'stream',
                   'x-severity' => logdl[Cx_severity],
                   'x-category' => logdl[Cx_category],
                   'x-event' => logdl[Cx_event],
                   'x-sname' => logdl[Cx_sname],
                   'datetime' => logdl[Cdate]+' '+logdl[Ctime],
                   'ip' => logdl[Cc_ip],
                   'c-port' => logdl[Cc_port],
                   'c-client-id' => logdl[Cc_client_id],
                   'sc-bytes' => logdl[Csc_bytes],
                   'cs-bytes' => logdl[Ccs_bytes],
                   'sc-stream-bytes' => logdl[Csc_stream_bytes],
                   'cs-stream-bytes' => logdl[Ccs_stream_bytes],
                   'x-stream-id' => logdl[Cx_stream_id],
                   'x-duration' => logdl[Cx_duration],
                   'x-ctx' => logdl[Cx_ctx],
                   'x-comment' => logdl[Cx_comment],
                   'x-file-size' => logdl[Cx_file_size],
                   'x-file-length' => logdl[Cx_file_length],
                   'md5' => md5
                  } )
    end
  end
end

