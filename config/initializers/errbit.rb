Airbrake.configure do |config|
  config.api_key = 'b71fdfa6df1899f6508c2e1cf3ab9c94'
  config.host    = 'err.alabs.org'
  config.port    = 443
  config.secure  = config.port == 443
end

# Desactiva globalmente la verficación del certificado SSL
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
