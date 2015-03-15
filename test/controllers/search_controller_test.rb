require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  def setup
    create_test_index
    # index_test_items
  end

  def teardown
    delete_test_index
  end

  test "get new" do
    get :new, :locale => 'es'
    if elasticsearch_available?
      assert_response :success
      assert_template 'search/show'
      assert_equal nil, session[:criterio_id]
    else
      assert_response :redirect
    end  
  end
  
  test "should create new criterio" do
    assert_difference 'Criterio.count', +1 do 
      post :create, :locale => 'es', :key => 'keyword', :value => 'noticia'
    end
    criterio=Criterio.last
    assert_equal 'keyword: noticia', criterio.title
    assert_response :redirect
    assert_redirected_to search_url(:id => criterio.id)
  end

  test "should get_create new criterio" do
    assert_difference 'Criterio.count', +1 do 
      get :create, :locale => 'es', :key => 'tags', :value => 'prueba'
    end
    criterio=Criterio.last
    assert_equal 'tags: prueba', criterio.title
    assert_response :redirect
    assert_redirected_to search_url(:id => criterio.id)
  end
  
  test "should show criterio" do
    index_test_items('News')
    criterio=criterios(:criterio_one)
    get :show, :locale => 'es', :id => criterio.id
    if elasticsearch_available?
      assert_response :success
      assert_template 'search/show'
      assert_equal 13, criterio.results_count
    else
      assert_response :redirect
    end
  end

  test "should show criterio json" do
    index_test_items('News')
    criterio=criterios(:criterio_one)
    get :show, :locale => 'es', :id => criterio.id, :format => :json
    assert_template 'search/show'
    assert_response :success
  end
  
  test "should show criterio with parent" do
    criterio=criterios(:criterio_two)
    get :show, :id => criterio.id, :locale => 'es'
    if elasticsearch_available?
      assert_response :success
      assert_template 'search/show'
      assert_equal 2, criterio.results_count
      assert_select 'div#criterio_results_container div.criterio_result', :count => 2
    else
      assert_response :redirect
    end
  end
  
  test "should destroy criterio" do
    criterio=criterios(:criterio_two)
    @request.session[:criterio_id]=criterio.id
    assert_no_difference 'Criterio.count' do
      delete :destroy, :locale => 'es', :id => criterio.id
    end  
    assert_response :redirect
    assert_redirected_to search_path(:id => session[:criterio_id])
  end
  
  test "should destroy first criterio" do
    criterio=criterios(:criterio_one)
    @request.session[:criterio_id]=criterio.id
    assert_no_difference 'Criterio.count' do
      delete :destroy, :locale => 'es', :id => criterio.id
    end  
    assert_response :redirect
    assert_redirected_to new_search_path
  end
  
end
