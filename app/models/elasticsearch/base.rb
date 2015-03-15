require 'net/http'
require 'uri'

ElasticsearchLogger = Logger.new(File.open(File.join(Rails.root, 'log/elasticsearch.log'), 'a'))

module Elasticsearch::Base

  def self.included(base)
    base.after_save :update_elasticsearch_server
    base.after_destroy :delete_from_elasticsearch_server
  end
  attr_accessor :score, :explanation

  # defines all params (facets, page size, etc)
  include ElasticsearchParams

  # defines all methods needed for indexing (create/delete methods and callbacks)
  include Elasticsearch::Index::InstanceMethods
  extend Elasticsearch::Index::ClassMethods

  # defines all methods needed for searching (queries, facets, etc.)
  extend Elasticsearch::Search::ClassMethods

  # Elasticsearch custom logger method.
  # Message is logged three times: ElasticsearchLogger, Rails Logger and STDOUT.
  def self.log(message)
    ElasticsearchLogger.info message
    Rails.logger.info message
    unless Rails.env.eql?('test')
      puts message
    end
  end
end
