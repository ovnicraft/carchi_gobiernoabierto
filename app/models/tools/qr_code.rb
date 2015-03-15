module Tools::QrCode

  def qr_code_path(locale = I18n.locale)
    File.join(Rails.root, "public", qr_code_url(locale))
  end
  
  def qr_code_url(locale = I18n.locale)
    File.join("/qr_codes/#{self.class.to_s.tableize}/#{id}","#{locale}.png")
  end
  
end