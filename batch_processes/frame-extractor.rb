#!<PATH to your ruby interpreter>
#
# rem to apt-get install flvmeta
# rem to apt-get install ffmpegthumbnailer
#
require 'rubygems'

flvfile = ARGV[0]
exit if flvfile == nil


basename = File.basename(flvfile, '.flv')
dirname = File.dirname(flvfile)

if !(File.exist?(dirname+'/frames/'))
  x = `mkdir #{dirname}/frames`
end


if !(Dir.entries(dirname+'/frames/').any? {|f| f.match(/#{basename}_/)})


  5.times do
    t=rand(100)
    ex=`/usr/bin/ffmpegthumbnailer -i#{flvfile} -o#{dirname}/frames/#{basename}_#{t}.jpg  -s0 -t#{t}% -q10`

  end

else
  puts "skipping ", flvfile
end
