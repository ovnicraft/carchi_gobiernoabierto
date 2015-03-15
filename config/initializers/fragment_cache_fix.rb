# Override the key_file_path method to get rid of those hash subdirs for frag cache files

ActiveSupport::Cache::FileStore.module_eval do
  def key_file_path(key)
    fname = key.to_s
    fname_paths = []
    # Make sure file name is < 255 characters so it doesn't exceed file system limits
    if fname.size <= 255
      fname_paths << fname
    else
      while fname.size > 255
        fname_paths << fname[0, 255]
        fname = fname[255, -1]
      end
    end
    File.join(cache_path, *fname_paths) + '.cache'
  end
end
