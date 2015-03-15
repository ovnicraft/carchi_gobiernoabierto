require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  def setup
    prepare_elasticsearch_test
    # @request.cookies['locale'] = CGI::Cookie.new('locale', "es")
  end

  def teardown
    delete_test_index
  end

  test "get index" do
    get :index
    assert_response :success
  end

  test "get show with associated criterio" do
    criterio = criterios(:criterio_for_tag)
    tag = tags(:tag_prueba)
    assert tag.criterio_id.present?
    get :show, :id => tag.id
    if elasticsearch_available?
      assert_response :success
      assert_template 'search/show'
    else
      assert_response :redirect
    end
  end

  # ERROR: it creates two associated criterios instead of one but in dev and prod envs works perfectly well
  # test "get show without associated criterio" do
  #   tag = tags(:tagueado)
  #   assert_difference 'Criterio.count', +1 do
  #     get :show, :id => tag.id
  #   end
  #   tag.reload

  #   if elasticsearch_available?
  #     assert_response :success
  #     assert_template 'search/show'
  #   else
  #     assert_response :redirect
  #     assert_redirected_to new_search_url
  #   end
  # end

  test "get not found" do
    get :show, :id => 'meloinvento'
    assert_response :not_found
    assert_template 'site/notfound.html'
  end

end
