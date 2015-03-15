module Elasticsearch::Index

  module InstanceMethods
    def fields_for_search
      if self.is_a?(Politician)
        h = {"public_name" => self.public_name,
            "role" => [self.public_role_en, self.public_role_es, self.public_role_eu].join('|'),
            "body_es" => self.description_es,
            "body_eu" => self.description_eu,
            "body_en" => self.description_en,
            "areas" => self.areas_for_elasticsearch,
            "organization" => self.organization_for_elasticsearch,
            "4suggestions" => [self.public_name, self.public_role_en, self.public_role_es, self.public_role_eu, self.description_es, self.description_eu, self.description_en, self.areas_for_elasticsearch, self.organization_for_elasticsearch].join('\n')
          }
      else
        h = {"title_es" => self.title_es,
            "title_eu" => self.title_eu,
            "title_en" => self.title_en,
            "body_es" => self.body_es.to_s.strip_html,
            "body_eu" => self.body_eu.to_s.strip_html,
            "body_en" => self.body_en.to_s.strip_html,
            "tags" => self.public_tags_for_elasticsearch,
            "politicianst" => self.politicians_for_elasticsearch,
            "areas" => self.areas_for_elasticsearch,
            "published_at" => self.date_for_elasticsearch,
            "year" => I18n.localize(self.date_for_elasticsearch, :format => '%Y'),
            "month" => AvailableLocales::AVAILABLE_LANGUAGES.keys.map(&:to_s).sort.map{|loc| I18n.localize(self.date_for_elasticsearch, :format => '%B', :locale => loc)}.join('|'),
            "organization" => self.organization_for_elasticsearch,
            "4suggestions" => [self.title_es, self.title_eu, self.title_en, self.body_es, self.body_eu, self.body_en, self.public_tags_for_elasticsearch, self.politicians_for_elasticsearch, self.areas_for_elasticsearch, self.organization_for_elasticsearch].join('\n')}
        if self.is_a?(News) || self.is_a?(Event)
          h.merge!({
            "speaker" => [self.speaker_en, self.speaker_es, self.speaker_eu].join(',')})
        end
        if self.is_a?(Video)
          h.merge!({
            "subtitles_es" => self.subtitles_es_to_text,
            "subtitles_eu" => self.subtitles_eu_to_text,
            "subtitles_en" => self.subtitles_en_to_text
            })
        end
        if self.is_a?(Debate)
          # use subtitle fields to store description
          h.merge!({
            "subtitles_es" => self.description_es.to_s.strip_html,
            "subtitles_eu" => self.description_eu.to_s.strip_html,
            "subtitles_en" => self.description_en.to_s.strip_html
            })
        end
      end
      h.merge!({"term" => AvailableLocales::AVAILABLE_LANGUAGES.keys.map(&:to_s).sort.map{|loc| I18n.translate('organizations.term', :term => self.term_for_elasticsearch, :locale => loc)}.join('|')}) if self.term_for_elasticsearch.present?
      h
    end

    def public_tags_for_elasticsearch
      tags_for_elasticsearch=[]
      self.public_tags_without_politicians.each do |tag|
        tags_for_elasticsearch << [tag.name_en, tag.name_es, tag.name_eu].join('|')
      end
      tags_for_elasticsearch.join(';')
    end

    def politicians_for_elasticsearch
      politicians_for_elasticsearch=[]
      self.politicians.each do |pol|
        politicians_for_elasticsearch << pol.public_name.strip
      end
      politicians_for_elasticsearch.join(';')
    end

    def areas_for_elasticsearch
      areas_for_elasticsearch=[]
      self.areas.each do |area|
        areas_for_elasticsearch << [area.name_en, area.name_es, area.name_eu].join('|')
      end
      areas_for_elasticsearch.join(';')
    end

    def date_for_elasticsearch
      if self.is_a?(Album) || self.is_a?(Proposal)
        self.created_at
      elsif self.is_a?(Event)
        self.starts_at
      else
        self.published_at || self.created_at
      end
    end

    def organization_for_elasticsearch
      self.organization.nil? ? '' : [self.organization.name_en, self.organization.name_es, self.organization.name_eu].join('|')
    end

    def term_for_elasticsearch
      if self.respond_to?(:department) && self.department
        self.department.term
      end
    end

    # FOR JSON SEARCH
    def starts_at_for_json
      date = if self.is_a?(Album) || self.is_a?(Proposal)
        self.created_at
      elsif self.is_a?(Event)
        self.starts_at
      else
        self.respond_to?(:published_at) ? self.published_at : self.created_at
      end
      date.strftime("%Y,%-m,%e")
    end

    def ends_at_for_json
      date = if self.is_a?(Album) || self.is_a?(Proposal)
        self.created_at
      elsif self.is_a?(Event)
        self.ends_at
      else
        self.respond_to?(:published_at) ? self.published_at : self.created_at
      end
      date.strftime("%Y,%-m,%e")
    end
    # END of FOR JSON SEARCH
    def update_elasticsearch_server
      begin
        if ((self.changed.include?('draft') || self.changed.include?('published_at')) && !self.published?) || (self.is_a?(Proposal) && !self.approved?)
          self.delete_from_elasticsearch_server
        elsif self.published? || (self.is_a?(Proposal) && self.approved?)
          h = self.fields_for_search
          # h.each {|k, v| h[k] = v.tildes if v.is_a?(String) && k.match(/\.analyzed/).nil?}
          uri=(URI.parse("#{Elasticsearch::Base::URI}/#{self.class.to_s.tableize}/#{self.id}"))
          logger.info "update_elasticsearch_server: #{uri.inspect}"
          Net::HTTP.start(uri.host, uri.port) do |http|
            headers = { 'Content-Type' => 'application/json'}
            data = h.to_json
            response = http.send_request("PUT", uri.request_uri, data, headers)
            # Elasticsearch::Base::log "Elasticsearch#update_elasticsearch_server: #{response.code} #{response.message} #{response.body}"
            Elasticsearch::Base::log "Elasticsearch#update_elasticsearch_server #{self.class.name}##{self.id} response: #{response.code} #{response.message}"
          end
        end
      rescue => e
        Elasticsearch::Base::log "Elastic search server is not available. Probably, #{self.class.name}##{self.id} has not been correctly indexed. Error: #{e}"
      end
    end

    def delete_from_elasticsearch_server
      begin
        uri=(URI.parse("#{Elasticsearch::Base::URI}/#{self.class.to_s.tableize}/#{self.id}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.send_request("DELETE", uri.request_uri)
          # Elasticsearch::Base::log "Elasticsearch#delete_from_elasticsearch_server #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "Elasticsearch#delete_from_elasticsearch_server #{self.class.name}##{self.id} response: #{response.code} #{response.message}"
        end
      rescue => e
        Elasticsearch::Base::log "Elastic search server is not available. Probably, #{self.class.name}##{self.id} has not been correctly deleted. ERROR: #{e}"
      end
    end
  end

  module ClassMethods
    def create_index
      begin
        uri=(URI.parse("#{Elasticsearch::Base::URI}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'application/json'}
          data = '{"settings" :
                    {"analysis" :
                      {"analyzer" :
                        { "default" : {"type": "snowball", "language" : "Spanish"},
                          "basque" : {"type" : "snowball", "language" : "Basque"},
                          "english": {"type" : "snowball", "language" : "English"},
                          "semicolon" : {"type" : "pattern", "pattern": ";", "lowercase": "false"}}
                      }
                    },
                    "mappings" :
                      {"news" :
                        {"properties" : {
                          "4suggestions" : {"type": "string", "analyzer": "standard"},
                          "title_eu" : {"type": "string", "analyzer": "basque"},
                          "title_en" : {"type": "string", "analyzer": "english"},
                          "body_eu" : {"type": "string", "analyzer": "basque"},
                          "body_en" : {"type": "string", "analyzer": "english"},
                          "published_at" : {"type" : "date"},
                          "tags" : {"type": "multi_field", "fields": {"tags": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "politicianst" : {"type": "multi_field", "fields": {"politicianst": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "month" : {"type": "string", "index": "not_analyzed"},
                          "term": {"type": "string", "index": "not_analyzed"}
                          }
                        },
                       "events" :
                        {"properties" : {
                          "4suggestions" : {"type": "string", "analyzer": "standard"},
                          "title_eu" : {"type": "string", "analyzer": "basque"},
                          "title_en" : {"type": "string", "analyzer": "english"},
                          "body_eu" : {"type": "string", "analyzer": "basque"},
                          "body_en" : {"type": "string", "analyzer": "english"},
                          "published_at" : {"type" : "date", "index" : "not_analyzed"},
                          "tags" : {"type": "multi_field", "fields": {"tags": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "politicianst" : {"type": "multi_field", "fields": {"politicianst": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "month" : {"type": "string", "index": "not_analyzed"},
                          "term": {"type": "string", "index": "not_analyzed"}
                          }
                         },
                        "pages" :
                         {"properties" : {
                          "4suggestions" : {"type": "string", "analyzer": "standard"},
                           "title_eu" : {"type": "string", "analyzer": "basque"},
                           "title_en" : {"type": "string", "analyzer": "english"},
                           "body_eu" : {"type": "string", "analyzer": "basque"},
                           "body_en" : {"type": "string", "analyzer": "english"},
                           "published_at" : {"type" : "date", "index" : "not_analyzed"},
                           "tags" : {"type": "multi_field", "fields": {"tags": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                           "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                           "politicianst" : {"type": "multi_field", "fields": {"politicianst": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                           "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                           "month" : {"type": "string", "index": "not_analyzed"},
                           "term": {"type": "string", "index": "not_analyzed"}
                           }
                          },
                         "proposals" :
                          {"properties" : {
                            "4suggestions" : {"type": "string", "analyzer": "standard"},
                            "title_eu" : {"type": "string", "analyzer": "basque"},
                            "title_en" : {"type": "string", "analyzer": "english"},
                            "body_eu" : {"type": "string", "analyzer": "basque"},
                            "body_en" : {"type": "string", "analyzer": "english"},
                            "published_at" : {"type" : "date"},
                            "tags" : {"type": "multi_field", "fields": {"tags": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "politicianst" : {"type": "multi_field", "fields": {"politicianst": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "month" : {"type": "string", "index": "not_analyzed"},
                            "term": {"type": "string", "index": "not_analyzed"}
                            }
                          },
                         "videos" :
                          {"properties" : {
                            "4suggestions" : {"type": "string", "analyzer": "standard"},
                            "title_eu" : {"type": "string", "analyzer": "basque"},
                            "title_en" : {"type": "string", "analyzer": "english"},
                            "published_at" : {"type" : "date"},
                            "tags" : {"type": "multi_field", "fields": {"tags": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "politicianst" : {"type": "multi_field", "fields": {"politicianst": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "month" : {"type": "string", "index": "not_analyzed"},
                            "term": {"type": "string", "index": "not_analyzed"}
                            }
                          },
                         "albums" :
                          {"properties" : {
                            "4suggestions" : {"type": "string", "analyzer": "standard"},
                            "title_eu" : {"type": "string", "analyzer": "basque"},
                            "title_en" : {"type": "string", "analyzer": "english"},
                            "body_eu" : {"type": "string", "analyzer": "basque"},
                            "body_en" : {"type": "string", "analyzer": "english"},
                            "published_at" : {"type" : "date", "index" : "not_analyzed"},
                            "tags" : {"type": "multi_field", "fields": {"tags": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "politicianst" : {"type": "multi_field", "fields": {"politicianst": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "month" : {"type": "string", "index": "not_analyzed"},
                            "term": {"type": "string", "index": "not_analyzed"}
                            }
                          },
                          "politicians" :
                           {"properties" : {
                            "4suggestions" : {"type": "string", "analyzer": "standard"},
                             "title_eu" : {"type": "string", "analyzer": "basque"},
                             "title_en" : {"type": "string", "analyzer": "english"},
                             "body_eu" : {"type": "string", "analyzer": "basque"},
                             "body_en" : {"type": "string", "analyzer": "english"},
                             "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                             "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                             "term": {"type": "string", "index": "not_analyzed"}
                            }
                          },
                          "debates" :
                           {"properties" : {
                            "4suggestions" : {"type": "string", "analyzer": "standard"},
                            "title_eu" : {"type": "string", "analyzer": "basque"},
                            "title_en" : {"type": "string", "analyzer": "english"},
                            "body_eu" : {"type": "string", "analyzer": "basque"},
                            "body_en" : {"type": "string", "analyzer": "english"},
                            "published_at" : {"type" : "date"},
                            "tags" : {"type": "multi_field", "fields": {"tags": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "areas" : {"type": "multi_field", "fields": {"areas": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "politicianst" : {"type": "multi_field", "fields": {"politicianst": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "organization" : {"type": "multi_field", "fields": {"organization": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                            "month" : {"type": "string", "index": "not_analyzed"},
                            "term": {"type": "string", "index": "not_analyzed"}
                            }
                          }
                        }
                      }'
          response = http.send_request("POST", uri.request_uri, data, headers)
          # Elasticsearch::Base::log "Elasticsearch#create_index response: #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "Elasticsearch#create_index response: #{response.code} #{response.message}"
          return response
        end
      rescue
        return nil
      end
    end

    def delete_index
      begin
        uri=(URI.parse("#{Elasticsearch::Base::URI}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.send_request("DELETE", uri.request_uri)
          # Elasticsearch::Base::log "Elasticsearch#delete_index response: #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "Elasticsearch#delete_index response: #{response.code} #{response.message}"
          return response
        end
      rescue
        return nil
      end
    end

    def create_related_index
      begin
        uri=(URI.parse("#{Elasticsearch::Base::RELATED_URI}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'application/json'}
          response = http.send_request("POST", uri.request_uri, headers.to_json)
          # Elasticsearch::Base::log "Elasticsearch#create_related_index response: #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "Elasticsearch#create_related_index response: #{response.code} #{response.message}"
          return response
        end
      rescue => e
        Elasticsearch::Base::log "ERROR creating related index #{e}"
        return nil
      end
    end

    def delete_related_index
      begin
        uri=(URI.parse("#{Elasticsearch::Base::RELATED_URI}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.send_request("DELETE", uri.request_uri)
          # Elasticsearch::Base::log "Elasticsearch#delete_related_index response: #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "Elasticsearch#delete_related_index response: #{response.code} #{response.message}"
          return response
        end
      rescue => e
        Elasticsearch::Base::log "ERROR deleting related index #{e}"
        return nil
      end
    end

    def create_bopv_index
      begin
        uri=(URI.parse("#{Elasticsearch::Base::BOPV_URI}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'application/json'}
          data = '{"settings" :
                    {"analysis" :
                      {"analyzer" :
                        { "default" : {"type": "snowball", "language" : "Spanish"},
                          "basque" : {"type" : "snowball", "language" : "Basque"},
                          "semicolon" : {"type" : "pattern", "pattern": ";", "lowercase": "false"}}
                      }
                    },
                    "mappings" :
                      {"orders" :
                        {"properties" : {
                          "title_eu" : {"type": "string", "analyzer": "basque"},
                          "body_eu" : {"type": "string", "analyzer": "basque"},
                          "published_at" : {"type" : "date"},
                          "fecha_disp" : {"type" : "date"},
                          "rango" : {"type": "multi_field", "fields": {"rango": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "seccion" : {"type": "multi_field", "fields": {"seccion": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "organo" : {"type": "multi_field", "fields": {"organo": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "materias" : {"type": "multi_field", "fields": {"materias": {"type": "string"},"analyzed":{"type" : "string", "analyzer": "semicolon"}}},
                          "month" : {"type": "string", "index": "not_analyzed"}
                          }
                        }
                      }
                    }'

          response = http.send_request("POST", uri.request_uri, data, headers)
          # Elasticsearch::Base::log "Elasticsearch#create_bopv_index response: #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "Elasticsearch#create_bopv_index response: #{response.code} #{response.message}"
          return response
        end
      rescue
        return nil
      end
    end

    def delete_bopv_index
      begin
        uri=(URI.parse("#{Elasticsearch::Base::BOPV_URI}"))
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.send_request("DELETE", uri.request_uri)
          # Elasticsearch::Base::log "Elasticsearch#delete_bopv_index response: #{response.code} #{response.message} #{response.body}"
          Elasticsearch::Base::log "Elasticsearch#delete_bopv_index response: #{response.code} #{response.message}"
          return response
        end
      rescue
        return nil
      end
    end

    # Consider using put_mapping delete_mapping
  end

end
