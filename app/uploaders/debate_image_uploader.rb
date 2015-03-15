#
# Uploader for the cover image for Debate
#
class DebateImageUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick

  def self.cache_from_io!(io_string, file_or_name)
    uploader = DebateImageUploader.new
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

  # 2DO: hay que tener una versión para la página del debate y otra para portada para la home y la lista
  # Por ahora hay dos campos en la tabla de debates, pero se generan todos los tamaños en los dos casos.

  version :thumb_70 do
    process :resize_to_fill => [70, 40]
  end

  version :bulletin_270 do
    process :resize_to_fit => [270, 115]
  end

  version :n372 do
    process :resize_to_fit => [372, 158]
  end

  # Version for the home
  version :cover do
    process :resize_to_fit => [1170, 500]
  end

  version :original do
  end

  # Provide a default URL as a default if there hasn't been a file uploaded
  # def default_url
  #   "/images/default/" + ["debate_default", "#{version_name}.png"].compact.join('_')
  # end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

end
