# Clean filename before upload to prevent errors
# In newer versions of paperclip:
Paperclip.interpolates :sanitized_basename do |attachment, style|
  attachment.original_filename.tildes.gsub(/#{File.extname(attachment.original_filename)}$/, "")
end


module Paperclip
  class Attachment
    # When attachment has been modified, access the original attachment file
    # before writes are flushed to disk.  The instance is the object with which this attachment is associated.

    # Created for instance validations that depend upon the uploaded file content of the attachment type.
    # Now we can easily access uploaded temp files before the attachment's instance has been saved.
    def tempfile
      return @queued_for_write[:original] if @queued_for_write
      nil
    end
  end
end


# Workaround to fix https://github.com/thoughtbot/paperclip/issues/1429
require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end


# Perform geometry detection without exif params
module Paperclip
  class GeometryDetector
    private 
    def geometry_string
      begin
        Paperclip.run(
          "identify",
          "-format '%wx%h' :file", {
          :file => "#{path}[0]"
          }, {
            :swallow_stderr => true
          }
        )
      rescue Cocaine::ExitStatusError
        ""
      rescue Cocaine::CommandNotFoundError => e
        raise_because_imagemagick_missing
      end
    end
  end
end 