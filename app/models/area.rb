class Area < ActiveRecord::Base
  translates :name, :description
  acts_as_ordered_taggable

  validates_presence_of :name_es
  validates_uniqueness_of :name_es

  scope :ordered, -> { order('position') }

  # Equipo del área
  has_many :area_users, -> { order('position') }, :dependent => :destroy
  has_many :users, -> { order('position') }, :through => :area_users

  has_many :followings, :dependent => :destroy, :as => :followed
  has_many :followers, :through => :followings, :source => :user

  alias_method :public_name, :name
  attr_accessor :area_tag_name

  # validates_format_of :area_tag_name, :with => /^_a_/

  validate :area_tag_name_format
  def area_tag_name_format
    if @area_tag_name.present?
      self.errors.add :area_tag_name, 'debe empezar por _a_' unless @area_tag_name.match(/^_a_/)
    end
  end

  def self.tags
    self.all.collect {|a| a.area_tag}
  end

  def area_tag_name=(value)
    @area_tag_name = value
    old_tags = self.tag_list
    self.tag_list = old_tags.select {|t| !t.match(/^_a_/)} + [value]
    return @area_tag_name
  end

  def area_tag
    @area_tag ||= self.tags.detect {|t| t.name_es.match(/^_a_/)}
    @area_tag
  end

  def area_tag_name
    self.area_tag.name_es if self.area_tag
  end

  def tag_name_es
    self.area_tag.name_es if self.area_tag
  end

  # Para descatar una noticia en un área hay que ponerle el tag "_destacado_<tag del area>"
  def featured_tag_name_es
    "_destacado#{self.tag_name_es}"
  end

  include Sluggable
  def title
    name
  end
  # Acciones del área
  include Tools::WithActions

  def to_yaml( opts = {} )
    YAML.quick_emit( self.id, opts ) { |out|
      out.map( taguri, to_yaml_style ) { |map|
        atr = @attributes.dup
        #atr.each_key {|key| atr[key] = "#{atr[key]}" if ["description_es", "description_eu", "description_en"].include?(key)}
        atr["tag_name_es"] = self.tag_name_es
        atr["filename4icon"] = self.icon_file_name
        map.add("attributes",  atr)
      }
    }
  end

  def approved_comments
    nil
  end

  def approved_arguments
    nil
  end

 if Settings.optional_modules.headlines
  def approved_headlines
    Headline.published.translated.recent.tagged_with(self.tag_name_es).limit(10)
  end

  def find_headlines_from_albiste
    if self.headline_keywords.present?
      ['es', 'eu'].each do |locale|
        begin
          query = {"size" => 10, "from" => 0,
            "query" => {"filtered" => {
              "filter" => {"and" => [{"term" => {"published_at" => {"from" => 3.day.ago.to_date.to_s, "to" => Date.today.to_s}}}, {"term" => {"locale" => locale}}]},
              "query" => {"query_string" => {"fields" => ["title^10"], "query" => self.headline_keywords.tildes, "analyzer" => "semicolon"}} }}}
          # query = {"size" => 10, "from" => 0,
          #   "query" => {"query_string" => {"fields" => ["title^3", "body"], "query" => self.headline_keywords.tildes}} }

          # puts "QUERY STRING #{query.inspect}"
          uri=(URI.parse("#{Elasticsearch::Base::ALBISTE_URI}/references/_search?pretty=true"))
          Net::HTTP.start(uri.host, uri.port) do |http|
            headers = { 'Content-Type' => 'application/json'}
            data = query.to_json
            response = http.send_request("GET", uri.request_uri, data, headers)
            # puts "Elasticsearch Response: #{response.code} #{response.message} #{response.body}"
            puts "Elasticsearch Response: #{response.code} #{response.message}"
            @code=response.code
            @body=response.body
          end
        rescue => e
          puts "ERROR. Elasticsearch is not available. #{e}"
          return false
        end
        if @code.eql?('200')
          results=Hash.new
          results['hits']=[]
          results['total_hits'] = JSON.parse(@body)['hits']['total']
          JSON.parse(@body)["hits"]["hits"].each do |result|
            es_item = result['_source']
            item = Headline.where({:source_item_id => result['_source']['source_item_id'].to_s, :source_item_type => result['_source']['source_item_type']})
            # before, only matching headlines were imported.
            # now, we import all and tag matching ones with area tag
            # unless item.present?
            #   item = Headline.create(result['_source'].merge(:tag_list => self.area_tag.name))
            # end
            unless item.present?
              item = Headline.create(result['_source'].merge(:tag_list => self.area_tag.name))
            else
              item = item.first
              # item.tag_list << self.area_tag.name
              if item.tag_list.present?
                # probably this item has been imported before, clear area_tag_list
                item.tag_list = []
              else
                item.tag_list << self.area_tag.name
              end
              unless item.save
                puts "Error updating headline tag list #{item.errors.tag_list}"
              end
            end
          end
          # return true
        else
          # return false
        end
      end
      puts "Headlines successfully created for area #{self.name}"
    end
  end

  def self.import_headlines_from_albiste
    ['es', 'eu'].each do |locale|
      begin
        ## Import headlines from today
        # query = {"size" => 10, "from" => 0,
        #   "query" => {"filtered" => {
        #     "filter" => {"and" => [{"term" => {"published_at" => Date.today.to_s}}, {"term" => {"locale" => locale}}]},
        #     "query" => {"query_string" => {"fields" => ["title^10"], "query" => "*", "analyzer" => "semicolon"}} }}}

        ## Import headlines for last three days
        query = {"size" => 10, "from" => 0,
          "query" => {"filtered" => {
            "filter" => {"and" => [{"range" => {"published_at" => {"from" => 3.day.ago.to_date.to_s, "to" => Date.today.to_s}}}, {"term" => {"locale" => locale}}]},
            "query" => {"query_string" => {"fields" => ["title^10"], "query" => "*", "analyzer" => "semicolon"}} }}}
        # puts "QUERY STRING #{query.inspect}"
        uri=(URI.parse("#{Elasticsearch::Base::ALBISTE_URI}/references/_search?pretty=true"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'application/json'}
          data = query.to_json
          response = http.send_request("GET", uri.request_uri, data, headers)
          # puts "Elasticsearch Response: #{response.code} #{response.message} #{response.body}"
          puts "Elasticsearch Response: #{response.code} #{response.message}"
          @code=response.code
          @body=response.body
        end
      rescue => e
        puts "ERROR. Elasticsearch is not available. #{e}"
        return false
      end
      if @code.eql?('200')
        results=Hash.new
        results['hits']=[]
        results['total_hits'] = JSON.parse(@body)['hits']['total']
        JSON.parse(@body)["hits"]["hits"].each do |result|
          es_item = result['_source']
          item = Headline.where({:source_item_id => result['_source']['source_item_id'].to_s, :source_item_type => result['_source']['source_item_type']})
          unless item.present?
            item = Headline.create(result['_source'])
          end
        end
        # return true
      else
        # return false
      end
    end
  end
 end

end
