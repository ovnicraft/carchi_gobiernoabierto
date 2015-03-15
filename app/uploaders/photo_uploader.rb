class PhotoUploader < CarrierWave::Uploader::Base

  # Include RMagick or ImageScience support
  #     include CarrierWave::RMagick
  #     include CarrierWave::ImageScience
  include CarrierWave::MiniMagick

  def self.cache_from_io!(io_string, file_or_name)
    uploader = PhotoUploader.new
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
  #     storage :s3

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.base_class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
  
  version :thumb_70 do
    process :resize_to_fill => [70, 70]
  end

  version :big_280 do
    process :resize_to_fill => [280, 280]
  end

  def contents_size
    manipulate! do |img|
      img.resize "#{500}x#{500}" if img[:width] > 500
      img = yield(img) if block_given?
      img
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded
  def default_url
    #"/assets/default/" + ["faceless_avatar", "#{version_name}.png"].compact.join('_')
    ActionController::Base.helpers.asset_path("default/" + ["faceless_avatar", "#{version_name}.png"].compact.join('_'))
  end

  # Process files as they are uploaded.
  #     process :scale => [200, 300]
  #
  #     def scale(width, height)
  #       # do something
  #     end

  # Create different versions of your uploaded files
  #     version :thumb do
  #       process :scale => [50, 50]
  #     end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  #     def extension_white_list
  #       %w(jpg jpeg gif png)
  #     end

  # Override the filename of the uploaded files
  #     def filename
  #       "something.jpg"
  #     end

end
