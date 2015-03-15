module ElasticsearchTestHelper

  def self.included(base)
    base.setup :check_elasticsearch_server_status
  end

  def check_elasticsearch_server_status
    @@elastic_search_server_checked ||= false
    if @@elastic_search_server_checked
    else
      unless elasticsearch_available?
        puts "\n----------\nWarning! ELASTICSEARCH SERVER IS NOT AVAILABLE AT #{Elasticsearch::Base::URI}\n----------\n"
      end
      @@elastic_search_server_checked = true
    end
  end

  def create_test_index
    Elasticsearch::Base::create_index
  end

  def index_test_items(type)
    type.classify.constantize.all.each do |item|
      item.update_elasticsearch_server
      item.update_elasticsearch_related_server if item.respond_to?(:update_elasticsearch_related_server) # only for news
    end
    sleep 2
  end

  def delete_test_index
    Elasticsearch::Base::delete_index
  end

  def prepare_elasticsearch_test(type=nil)
    delete_test_index
    create_test_index
    if type.present?
      if type.eql?('related')
        Elasticsearch::Base::delete_related_index
        Elasticsearch::Base::create_related_index
      else
        index_test_items(type)
      end
    end
  end

  def prepare_bopv_elasticsearch_test
    Elasticsearch::Base::delete_bopv_index
    Elasticsearch::Base::create_bopv_index
  end

  # In elasticsearch < 1.X: response_body['exists']
  # In elasticsearch >= 1.X: response_body['found']
  def assert_indexed_in_elasticsearch(item, index=Elasticsearch::Base::URI)
    response_body = get_item_from_elasticsearch(item, true, index)
    assert response_body['found'].eql?(true), "Expected #{item} to be indexed in elasticsearch, but it isn't"
  end

  def assert_deleted_from_elasticsearch(item, index=Elasticsearch::Base::URI)
    response_body = get_item_from_elasticsearch(item, false, index)
    assert response_body['found'].nil? || response_body['found'].eql?(false), "Expected #{item} not to be indexed in elasticsearch, but it is"
  end
  alias_method :assert_not_indexed_in_elasticsearch, :assert_deleted_from_elasticsearch

  def get_item_from_elasticsearch(actual, expected_return, index=Elasticsearch::Base::URI)
    uri=(URI.parse("#{index}" + "/#{actual.class.to_s.tableize}/#{actual.id}"))
    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        headers = { 'Content-Type' => 'application/json'}
        response = http.send_request("GET", uri.request_uri, '', headers)
        return JSON.parse(response.body)
      end
    rescue => e
      return {"found" => expected_return}
    end
  end

  def elasticsearch_available?
    uri=URI.parse("#{Elasticsearch::Base::URI}")
    begin
      Net::HTTP.start(uri.host, uri.port) do |http|
        headers = { 'Content-Type' => 'application/json'}
        response = http.send_request("GET", uri.request_uri, '', headers)
        return true
      end
    rescue   => e
      return false
    end
  end

end

