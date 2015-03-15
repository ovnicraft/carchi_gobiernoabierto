require 'carrierwave/mount'
class Corporative
  include ActiveModel::Model

  extend CarrierWave::Mount
  mount_uploader :logo, Corporative::LogoUploader
  mount_uploader :footer, Corporative::FooterUploader

  # Para poder validar el input
  attr_accessor :site_name, :publisher_name, :publisher_address,
    :email_addresses_from, :email_addresses_contact, :email_addresses_proposal_moderators, :email_addresses_orphan_videos_responsibles,
    :social_networks_twitter, :social_networks_facebook, :social_networks_flickr, :social_networks_youtube,
    :logo, :footer,
    :optional_modules_proposals, :optional_modules_debates, :optional_modules_headlines, :optional_modules_streaming

  validates_presence_of :site_name, :publisher_name, :publisher_address,
    :email_addresses_from, :email_addresses_contact, :email_addresses_proposal_moderators, :email_addresses_orphan_videos_responsibles, 
    :message => I18n.t("activerecord.errors.messages.blank")

  validates_format_of :email_addresses_from, :email_addresses_contact, :email_addresses_proposal_moderators, :email_addresses_orphan_videos_responsibles,
    :with => /(\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})(,\s*([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,}))*\z)/i, 
    :message => I18n.t("activerecord.errors.messages.invalid")

  validates_format_of :social_networks_twitter, :social_networks_facebook, :social_networks_flickr, :social_networks_youtube,
    :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix, :allow_blank => true,
    :message => I18n.t("activerecord.errors.messages.invalid")

  def initialize(attributes = {})
    self.logo = attributes.delete('logo')
    self.footer = attributes.delete('footer')

    corporative_email = attributes.delete('corporative_email')
    if corporative_email && !attributes.has_key?('email_attributes')
      attributes['email_addresses'] = {'from' => corporative_email, 'contact' => corporative_email, 'proposal_moderators' => corporative_email, 'orphan_videos_responsibles' => corporative_email}
    end

    # Los atributos que no se pasan por formulario se cogen del fichero yml
    d = YAML::load_file(Corporative.file_name) #Load
    merged_attributes = d.delete_if {|k,v| k.eql?("customized")}.merge(attributes)

    # Asigno los valores a los atributos "validables"
    @raw_attributes = {}
    merged_attributes.each do |name, value|
      if value.is_a?(Hash)
        value.each do |k, v|
          send("#{name}_#{k}=", v)
          @raw_attributes[name] = Hash.new unless @raw_attributes.has_key?(name)
          @raw_attributes[name][k] = booleanish_to_boolean(v)
        end
      else
        send("#{name}=", value)
        @raw_attributes[name] = booleanish_to_boolean(value)
      end
    end
  end

  def self.file_name
    File.join(Rails.root, 'config', 'settings.yml')
  end

  def save
    if valid?
      if self.logo
        uploader = Corporative::LogoUploader.new
        uploader.store!(self.logo)
      end

      if self.footer
        uploader = Corporative::FooterUploader.new
        uploader.store!(self.footer)
        FileUtils.copy(File.join(Rails.root, 'app', 'assets', 'images', 'footer_es.jpg'), File.join(Rails.root, 'app', 'assets', 'images', 'footer_eu.jpg'))
      end

      #d = YAML::load_file(Corporative.file_name) #Load
      File.open(Corporative.file_name, 'w') {|f| f.write JSON(@raw_attributes.to_json).merge("customized" => true).to_yaml } #Store

      Settings.reload!
    else
      false
    end
  end

  def persisted?
    false
  end

  private
  def booleanish_to_boolean(val)
    if ['true', '1'].include?(val)
      true
    elsif ['false', '0'].include?(val)
      false
    else
      val
    end
  end
end
