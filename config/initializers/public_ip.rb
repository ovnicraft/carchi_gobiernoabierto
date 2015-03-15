class PublicIp
  def self.get
    begin
      open('http://whatismyip.akamai.com').read
    rescue
      puts  "PublicIp could not get your public IP. Please set a value for multimedia.url in #{File.join(Rails.root, 'config', 'irekia.yml')}"
      return ""
    end
  end
end
