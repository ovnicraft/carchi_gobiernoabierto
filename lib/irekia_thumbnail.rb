class IrekiaThumbnail
  def self.make(photo, geometry, size)
    begin
      dirname, filename = Pathname.new(photo).split
      # I'll do it with Paperclip to harness the "90x90#" geometry syntax
      temp_file = Paperclip::Thumbnail.make(File.open(photo), geometry: geometry)
      FileUtils.mkdir_p("#{dirname}/#{size}/") unless File.directory?("#{dirname}/#{size}/")
      thumbnail_file = "#{dirname}/#{size}/#{filename}"
      FileUtils.mv(temp_file.path, thumbnail_file) 
      FileUtils.chmod 0666, thumbnail_file
      temp_file.close
    rescue => error
      raise IrekiaThumbnailError, "There was an error generating thumbnail of size #{size} for #{photo}: #{error}"
    end
  end
end

class IrekiaThumbnailError < StandardError #:nodoc:
end
