#
# Uploader for the header images for Debate.
#
class DebateHeaderUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick

  def self.cache_from_io!(io_string, file_or_name)
    uploader = DebateHeaderUploader.new
    tempfile = if file_or_name.is_a?(String)
      tempfile = Tempfile.new(file_or_name)
      tempfile.write io_string.read#.force_encoding('UTF-8')
      tempfile
    else
      file_or_name.tempfile
    end
    uploader.cache!(tempfile)
    tempfile.close
    tempfile.unlink
    uploader
  end
  
  # Choose what kind of storage to use for this uploader
  storage :file

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :original do
  end

  version :header do
    process :resize_to_fill => [1170, 160]
  end


  # Provide a default URL as a default if there hasn't been a file uploaded
  # def default_url
  #   "/images/default/" + ["debate_header_img_default", "#{version_name}.png"].compact.join('_')
  # end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end
  
end
