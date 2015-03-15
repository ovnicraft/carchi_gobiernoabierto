class Order < ActiveRecord::Base
  translates :titulo, :texto, :rango, :seccion, :materias, :dept, :ref_ant, :ref_pos, :vigencia, fallback: :any

  has_many :recommendation_ratings, -> { order("updated_at DESC") }, :as => :source, :dependent => :destroy

  # validates_translation_of :rango, :seccion, :titulo, :texto
  validates :rango, :seccion, :titulo, :texto, presence: true
  validates_presence_of :fecha_bol, :no_bol, :no_orden
  validates_uniqueness_of :no_orden, :case_sensitive => false

  before_validation :clean
  after_save :update_elasticsearch_server
  after_save :clear_cache
  after_destroy :delete_from_elasticsearch_server
  after_destroy :clear_cache

  alias_attribute :title, :titulo
  alias_attribute :title_es, :titulo_es
  alias_attribute :title_eu, :titulo_eu
  alias_attribute :body, :texto
  alias_attribute :body_es, :texto_es
  alias_attribute :body_eu, :texto_eu

  include CachedMethods
  include Tools::Clickthroughable

  def to_param
    self.no_orden
  end

  def draft
    false
  end

  def show_in_irekia?
    true
  end
  alias_method :show_in_irekia, :show_in_irekia?

  def published?
    true
  end

  def enet_url
 "https://www.lehendakaritza.ejgv.euskadi.net/r48-bopv2/#{I18n.locale.eql?(:eu) ? 'eu' : 'es'}/bopv2/datos/#{self.fecha_bol.year}/#{self.fecha_bol.strftime("%m")}/#{self.no_orden[2..-1]}#{I18n.locale.eql?('eu') ? 'e' : 'a'}.shtml"
  end

  def pretty_materias
    self.materias.split(';').join('; ')
  end

  def self.match_attribute_in_es(an, line)
    an = case line
      when /^\.DEPARTAMENTO:/, /^\.\.DEPA:/
        "dept_es"
      when /^\.FECHA BOLETIN:/, /^\.\.FEBO:/
        "fecha_bol"
      when /^\.FECHA DISPOSICION:/,  /^\.\.FEDI:/
        "fecha_disp"
      when /^\.NUMERO BOLETIN:/, /^\.\.NBOL:/
        "no_bol"
      when /^\.NUMERO ORDEN:/, /^\.\.NORD:/
        "no_orden"
      when /^\.SECCION:/, /^\.\.SECC:/
        "seccion_es"
      when /^\.RANGO:/, /^\.\.RANG:/
        "rango_es"
      when /^\.MATERIAS:/, /^\.\.MATE:/
        "materias_es"
      when /^\.TITULO:/, /^\.\.TITU:/
        "titulo_es"
      when /^\.TEXTO:/, /^\.\.TEXT:/
        "texto_es"
      when /^\.NUMERO DISPOSICION:/, /^\.\.NUMD:/
        "no_disp"
      when /^\.REF ANTERIOR:/, /^\.\.REFA:/
        "ref_ant_es"
      when /^\.REF POSTERIOR:/, /^\.\.REPO:/
        "ref_pos_es"
      when /^\.VIGENCIA:/, /^\.\.VIGE:/
        "vigencia_es"
      else
        an
    end
    return an
  end

  def self.match_attribute_in_eu(an, line)
    an = case line
      when /^\.SAILA:/, /^\.\.DEPA:/
        "dept_eu"
      when /^\.ALDIZKARIAREN DATA:/, /^\.\.FEBO:/
        "fecha_bol"
      when /^\.XEDAPENAREN DATA:/,  /^\.\.FEDI:/
        "fecha_disp"
      when /^\.ALDIZKARIAREN ZENBAKIA:/, /^\.\.NBOL:/
        "no_bol"
      when /^\.HURRENKENAREN ZENBAKIA:/, /^\.\.NORD:/
        "no_orden"
      when /^\.SEKZIOA:/, /^\.\.SECC:/
        "seccion_eu"
      when /^\.MAILA:/, /^\.\.RANG:/
        "rango_eu"
      when /^\.GAIAK:/, /^\.\.MATE:/
        "materias_eu"
      when /^\.IZENBURUA:/, /^\.\.TITU:/
        "titulo_eu"
      when /^\.TESTUA:/, /^\.\.TEXT:/
        "texto_eu"
      when /^\.XEDAPENAREN ZENBAKIA:/, /^\.\.NUMD:/
        "no_disp"
      when /^\.AURREKO ERREFERENTZIAK:/, /^\.\.REFA:/
        "ref_ant_eu"
      when /^\.GEROKO ERREFERENTZIAK:/, /^\.\.REPO:/
        "ref_pos_eu"
      when /^\.NOIZ JARRI DEN INDARREAN:/, /^\.\.VIGE:/
        "vigencia_eu"
      else
        an
    end
    return an
  end

  #### Search methods ####

  attr_accessor :score, :total_rating, :explanation

  def my_fields_for_search
    h = {
      "title_es" => self.titulo_es,
      "title_eu" => self.titulo_eu,
      "body_es" => self.texto_es,
      "body_eu" => self.texto_eu,
      "published_at" => self.fecha_bol,
      "fecha_disp" => self.fecha_disp,
      "materias" => self.materias_for_elasticsearch,
      "rango" => [self.rango_es, self.rango_es, self.rango_eu].join('|'),
      "seccion" => [self.seccion_es, self.seccion_es, self.seccion_eu].join('|'),
      "organo" => [self.dept_es, self.dept_es, self.dept_eu].join('|'),
      "no_bol" => self.no_bol,
      "no_orden" => self.no_orden,
      "no_disp" => self.no_disp,
      "year" => I18n.localize(self.fecha_bol, :format => '%Y'),
      "month" => AvailableLocales::AVAILABLE_LANGUAGES.keys.map(&:to_s).sort.map{|loc| I18n.localize(self.fecha_bol, :format => '%B', :locale => loc)}.join('|')}
    h
  end

  def update_elasticsearch_server
    begin
      h= self.my_fields_for_search
      h.each {|k, v| h[k] = v.tildes if v.is_a?(String) && k.match(/_an/).nil?}
      uri=(URI.parse("#{Elasticsearch::Base::BOPV_URI}/#{self.class.to_s.tableize}/#{self.id}"))
      Net::HTTP.start(uri.host, uri.port) do |http|
        headers = { 'Content-Type' => 'application/json'}
        data = h.to_json
        response = http.send_request("PUT", uri.request_uri, data, headers)
        # puts "Elasticsearch Response: #{response.code} #{response.message} #{response.body}"
        # puts "Elasticsearch Response: #{response.code} #{response.message}"
      end
    rescue => e
      Rails.logger.error "Elasticsearch server is not available. Probably, this item has not been correctly indexed. #{e}"
    end
  end

  def delete_from_elasticsearch_server
    begin
      uri=(URI.parse("#{Elasticsearch::Base::BOPV_URI}/#{self.class.to_s.tableize}/#{self.id}"))
      Net::HTTP.start(uri.host, uri.port) do |http|
        response = http.send_request("DELETE", uri.request_uri)
        # puts "Elasticsearch Response: #{response.code} #{response.message} #{response.body}"
        # puts "Elasticsearch Response: #{response.code} #{response.message}"
      end
    rescue => e
      logger.info "Elasticsearch server is not available. Probably, this item has not been correctly indexed. #{e}"
    end
  end

  def materias_for_elasticsearch
    list = []
    if self.materias_es.present? && self.materias_eu.present?
      list_es = self.materias_es.split(';')
      list_eu = self.materias_eu.split(';')
      for i in 0..[list_es.size, list_eu.size].max do
        list << [list_es[i], list_es[i], list_eu[i]].join('|')
      end
    elsif self.materias_es.present? || self.materias_eu.present?
      list_es = (self.materias_es || self.materias_eu).split(';')
      list_es.each do |item|
        list << [item, item, item].join('|')
      end
    end
    list.join(';')
  end

  def starts_at_for_json
    self.fecha_bol.strftime("%Y,%m,%d")
  end
  alias_method :ends_at_for_json, :starts_at_for_json

  #### \Search methods ####

  def self.related_coefficient
    0.2
  end

  def cache_path(locale=I18n.locale)
    "#{locale}/orders/#{self.no_orden[0..3]}/#{self.no_orden[4..5]}/#{self.no_orden[6..-1]}_in_related"
  end

  private
  def clean
    ['materias_es', 'materias_eu', 'dept_es', 'dept_eu'].each do |att|
      if self.send(att).present?
        self.send("#{att}=", self.send(att).split(";").map{|m| m.strip.strip_html}.join(";"))
      end
    end

    ['titulo_es', 'titulo_eu', 'ref_ant_es', 'ref_ant_eu', 'ref_pos_es', 'ref_pos_eu'].each do |att|
      if self.send(att).present?
        self.send("#{att}=", self.send(att).strip.strip_html)
      end
    end

    ['no_bol', 'no_disp', 'no_orden', 'rango_es', 'rango_eu', 'seccion_es', 'seccion_eu', 'texto_es', 'texto_eu'].each do |att|
      if self.send(att).present?
        self.send(att).strip!
      end
    end
  end

  def clear_cache
    # Order's cache expiration cannot be done via a Sweeper because there is no controller to attach it to.
    AvailableLocales::AVAILABLE_LANGUAGES.keys.each do |locale|
      file = "#{Rails.root}/cache/fragment/views/#{self.cache_path(locale)}.cache"

      FileUtils.rm(file) if File.exists?(file)
    end
  end


end
