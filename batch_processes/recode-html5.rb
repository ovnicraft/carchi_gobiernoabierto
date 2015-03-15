#!<PATH to your ruby interpreter>
#
# rem to apt-get install libav-tools
# rem to apt-get install libavcodec-extra
#
#

flvfile = ARGV[0]
exit if flvfile == nil

basename = File.basename(flvfile, '.flv')
dirname = File.dirname(flvfile)

if !(File.exist?(dirname+'/html5/'))
  x = `mkdir #{dirname}/html5`
end


if !(Dir.entries(dirname+'/html5/').any? {|f| f.match(/#{basename}.m4v/)})
  x1 = `avconv -i #{flvfile} -vcodec libx264 -acodec libvo_aacenc -r 30000/1001 #{dirname}/html5/#{basename}.m4v`
else
  puts "skipping ", flvfile
end

b.stop
