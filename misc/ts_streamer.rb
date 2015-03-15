#!/usr/bin/ruby
#
# uso: find /web/jails/agencia/home/jagencia/2010/ -name \*.flv -type f -mtime -10 -exec /usr/local/bin/ts_streamer.rb {} \;
#

require 'fileutils'

flvfile = ARGV[0]
exit if flvfile == nil

exit if File.exists? "/var/tmp/s4_running_lock"

basename = File.basename(flvfile, '.flv')
dirname = File.dirname(flvfile)
tspuburl = dirname.sub(/\/web\/jails\/agencia\/home\/jagencia/,'http://bideoak2.euskadi.net')+'/ts/'

if !(File.exist?(dirname+'/ts/'))
  FileUtils.mkdir "#{dirname}/ts"
end


if !(Dir.entries(dirname+'/ts/').any? {|f| f.match(/#{basename}.m3u8/)})

  p1 = `/usr/local/bin/ffmpeg -i #{flvfile} -f mpegts -acodec libmp3lame -ar 48000 -ab 64k -s 320x240 -vcodec libx264 -b 96k -flags +loop -cmp +chroma -partitions +parti4x4+partp8x8+partb8x8 -subq 5 -trellis 1 -refs 1 -coder 0 -me_range 16 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -bt 200k -maxrate 96k -bufsize 96k -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -level 30 -aspect 320:240 -g 30 -async 2 #{dirname}/ts/#{basename}.ts`

  FileUtils.cd("#{dirname}/ts/")
  p2 = ` /usr/local/bin/segmenter #{basename}.ts 10 #{basename} #{basename}.m3u8  #{tspuburl}`

else
  puts "skipping ", flvfile
end


