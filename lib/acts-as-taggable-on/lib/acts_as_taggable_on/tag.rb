# coding: utf-8
module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    extend ActsAsTaggableOn::Utils

    #attr_accessible :name if defined?(ActiveModel::MassAssignmentSecurity)

    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'

    ### VALIDATIONS:
    
    ######### Added by <tania@efaber.net> ##########
    # validates_presence_of :name
    # validates_uniqueness_of :name, :if => :validates_name_uniqueness?
    # validates_length_of :name, :maximum => 255

    translates :name, :sanitized_name
    belongs_to :criterio 
    has_many :clicks_from, -> { order("created_at DESC") }, :class_name => "Clickthrough", :foreign_key => "click_source_id", :as => :click_source, :dependent => :destroy

    before_validation :set_name_in_every_language

    validates_presence_of :name_es, :name_eu, :name_en
    validates_uniqueness_of :name_es, :name_eu, :name_en, :if => :validates_name_uniqueness?
    validates_length_of :name_es, :name_eu, :name_en, :maximum => 255
    # duplicated
    # validate :validates_presence_of_any_language

    before_save :set_sanitized_names
    before_save :create_associated_criterio
    before_update :set_as_translated_if_every_language_is_different
    after_update :reindex_tagged_documents

    PUBLIC_CONDITIONS = "name_es NOT LIKE E'\\\\_%'"
    PRIVATE_CONDITIONS = "name_es LIKE E'\\\\_%'"
    POLITICIANS_CONDITIONS = "kind LIKE E'Político'"
    LANGUAGES = [:es, :eu, :en]

    scope :all_public, -> { where(PUBLIC_CONDITIONS) }
    scope :all_private, -> { where(PRIVATE_CONDITIONS) }
    scope :politicians, -> { where(POLITICIANS_CONDITIONS)}
    ########## End of added by <tania@efaber.net> ##########

    # monkey patch this method if don't need name uniqueness validation
    def validates_name_uniqueness?
      false
    end

    ### SCOPES:

    ########## Modified by <tania@efaber.net> to support translations ##########
    # def self.named(name)
    #   if ActsAsTaggableOn.strict_case_match
    #     where(["name = #{binary}?", name])
    #   else
    #     where(["lower(name) = ?", name.downcase])
    #   end
    # end

    # def self.named_any(list)
    #   if ActsAsTaggableOn.strict_case_match
    #     clause = list.map { |tag|
    #       sanitize_sql(["name = #{binary}?", as_8bit_ascii(tag)])
    #     }.join(" OR ")
    #     where(clause)
    #   else
    #     clause = list.map { |tag|
    #       lowercase_ascii_tag = as_8bit_ascii(tag, true)
    #       sanitize_sql(["lower(name) = ?", lowercase_ascii_tag])
    #     }.join(" OR ")
    #     where(clause)
    #   end
    # end

    # def self.named_like(name)
    #   clause = ["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(name)}%"]
    #   where(clause)
    # end

    # def self.named_like_any(list)
    #   clause = list.map { |tag|
    #     sanitize_sql(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(tag.to_s)}%"])
    #   }.join(" OR ")
    #   where(clause)
    # end

    def self.named(name)
      if ActsAsTaggableOn.strict_case_match
        where(["name_es = #{binary}? OR name_eu = #{binary}? OR name_en = #{binary}?", name, name, name])
      else
        where(["lower(name_es) = ? OR lower(name_eu) = ? OR lower(name_en) = ?", name.downcase, name.downcase, name.downcase])
      end
    end

    def self.named_any(list)
      if ActsAsTaggableOn.strict_case_match
        clause = list.map { |tag|
          sanitize_sql(["name_es = #{binary}? OR name_eu = #{binary}? OR name_en = #{binary}?", as_8bit_ascii(tag), as_8bit_ascii(tag), as_8bit_ascii(tag)])
        }.join(" OR ")
        where(clause)
      else
        clause = list.map { |tag|
          # lowercase_ascii_tag = as_8bit_ascii(tag).downcase
          lowercase_ascii_tag = as_8bit_ascii(tag, true)
          sanitize_sql(["lower(name_es) = ? OR lower(name_eu) = ? OR lower(name_en) = ?", lowercase_ascii_tag, lowercase_ascii_tag, lowercase_ascii_tag])
        }.join(" OR ")
        where(clause)
      end
    end

    def self.named_like(name)
      clause = ["name_es #{like_operator} ? ESCAPE '!' OR name_eu #{like_operator} ? ESCAPE '!' OR name_en #{like_operator} ? ESCAPE '!'", "%#{escape_like(name)}%", "%#{escape_like(name)}%", "%#{escape_like(name)}%"]
      where(clause)
    end

    def self.named_like_any(list)
      clause = list.map { |tag|
        sanitize_sql(["name_es #{like_operator} ? ESCAPE '!' OR name_eu #{like_operator} ? ESCAPE '!' OR name_en #{like_operator} ? ESCAPE '!'", "%#{escape_like(tag.to_s)}%", "%#{escape_like(tag.to_s)}%", "%#{escape_like(tag.to_s)}%"])
      }.join(" OR ")
      where(clause)
    end

    ########## End of Modified by <tania@efaber.net> to support translations ##########

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name)
      if (ActsAsTaggableOn.strict_case_match)
        self.find_or_create_all_with_like_by_name([name]).first
      else
        named_like(name).first || create(:name => name)
      end
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = Array(list).flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list)

      list.map do |tag_name|
        comparable_tag_name = comparable_name(tag_name)
        existing_tag = existing_tags.detect { |tag| comparable_name(tag.name) == comparable_tag_name }

        existing_tag || Tag.create(:name => tag_name)
      end
    end

    ########## Added by <tania@efaber.net> ##########
    def self.name_columns
      LANGUAGES.collect {|l| "name_#{l}"}
    end
    
    def self.sanitized_name_columns
      LANGUAGES.collect {|l| "sanitized_name_#{l}"}
    end

    def self.duplicated_tags
      #find_by_sql("SELECT distinct on (t1.id) t1.id, t1.name_es FROM tags t1, tags t2 
      #  WHERE t1.id<>t2.id AND t1.name_es = t2.name_es AND t1.name_eu = t2.name_eu AND t1.name_en = t2.name_en")
      find_by_sql("SELECT distinct on (t1.id) t1.id, t1.name_es, t1.sanitized_name_es, t1.name_eu, t1.sanitized_name_eu, t1.kind, t1.kind_info FROM tags t1, tags t2 
         WHERE t1.id<>t2.id AND t1.sanitized_name_es = t2.sanitized_name_es AND t1.sanitized_name_eu = t2.sanitized_name_eu AND t1.sanitized_name_en = t2.sanitized_name_en")
    end

    ########## End of added by <tania@efaber.net> ##########

    ### INSTANCE METHODS:

    def ==(object)
      super || (object.is_a?(Tag) && name == object.name)
    end

    def to_s
      name
    end

    def count
      read_attribute(:count).to_i
    end

    ########## Added by <tania@efaber.net> ##########
    def reindex_tagged_documents
      if name_es_changed? || name_eu_changed? || name_en_changed?
        Document.tagged_with(self.name_es).each do |doc|
          doc.update_elasticsearch_server if doc.respond_to?(:update_elasticsearch_server)
        end
      end
    end       

    # GC related stuff
    def gc_link
      l = nil
      if Rails.configuration.external_urls[:guia_uri]
        if self.kind_info.present?
          l = case self.kind
            when 'Persona'
              Rails.configuration.external_urls[:guia_uri] + "/#{I18n.locale}/people/#{self.kind_info.to_i}"
            when 'Entidad'
              Rails.configuration.external_urls[:guia_uri] + "/#{I18n.locale}/entities/#{self.kind_info.to_i}"
          end
        end
      end
      return l
    end

    def translated_to?(locale)
      res = self.translated? || locale.eql?("es")
      if !res
        txt = self.send("name_#{locale}")
        res = (txt.eql?(self.name_es) || txt.blank?) ? false : true 
      end

      res
    end           
    
    def criterio_title
      "tags: #{self.name_en}|#{self.name_es}|#{self.name_eu}"
    end
    
    # def validates_presence_of_any_language
    #   names_empty = ActsAsTaggableOn::Tag.name_columns.collect {|c| c if self.send(c).blank?}.compact
    #   if names_empty.length == ActsAsTaggableOn::Tag.name_columns.length
    #     ActsAsTaggableOn::Tag.name_columns.each do |t|
    #       errors.add t, "El nombre no puede estar vacío"
    #     end
    #   else
    #     true
    #   end
    # end
    
    def set_name_in_every_language
      nonempty_names = ActsAsTaggableOn::Tag.name_columns.collect {|c| self.send(c) unless self.send(c).blank?}.compact
      LANGUAGES.each do |l|
        self.send("name_#{l}=", nonempty_names[0]) if self.send("name_#{l}").blank?
      end
    end
    
    def set_sanitized_names
      LANGUAGES.each do |l|
        self.send("sanitized_name_#{l}=", self.send("name_#{l}").to_tag)
      end
    end
    
    # Para cada tag crear el criterio asociado, solo si es visible
    def create_associated_criterio
      if self.name_es.match(/^_/).nil?
        if self.criterio.present? && (self.name_es_changed? || self.name_eu_changed? || self.name_en_changed?)
          self.criterio.update_attribute(:title, self.criterio_title)
        else             
          self.create_criterio(:title => self.criterio_title, :ip => '127.0.0.1')
        end
      end  
    end  
    
    def all_languages_different
      ActsAsTaggableOn::Tag.name_columns.collect {|c| self.send(c)}.uniq.length == ActsAsTaggableOn::Tag.name_columns.length
    end
    
    def set_as_translated_if_every_language_is_different
      if all_languages_different
        self.translated = true 
      else
        true
      end
    end
    
    # we want to have the tag name in urls
    def to_param
      sanitized_name
    end
    ########## End of added by <tania@efaber.net> ##########

    class << self
      private

      def comparable_name(str)
        if ActsAsTaggableOn.strict_case_match
          as_8bit_ascii(str)
        else
          as_8bit_ascii(str, true)
        end
      end

      def binary
        using_mysql? ? "BINARY " : nil
      end

      def as_8bit_ascii(string, downcase=false)
        string = string.to_s.dup.mb_chars
        string.downcase! if downcase
        if defined?(Encoding)
          string.to_s.force_encoding('BINARY')
        else
          string.to_s
        end
      end
    end
  end
end
