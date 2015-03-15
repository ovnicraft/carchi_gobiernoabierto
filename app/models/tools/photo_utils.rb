class Tools::PhotoUtils
  def self.photo_size_path(path, size="original")
    path = Pathname.new(path)
    return "#{path.dirname}/#{size}/#{path.basename}"
  end
end