# Tests para URL-s que ya no son activas.
require 'test_helper'

class ObsoleteUrlsTest < ActionDispatch::IntegrationTest
  
  ["/es/events/SBI04.SDP"].each_with_index do |url, i|
    test "url #{i}" do
      get url
      assert_response :not_found
    end
  end
end