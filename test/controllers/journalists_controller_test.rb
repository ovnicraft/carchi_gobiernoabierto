require 'test_helper'

class JournalistsControllerTest < ActionController::TestCase
  
  test "should get new" do
    get :new
    assert_response :success
    assert_template "new"
  end
  
  test "should post create with errors" do
    assert_no_difference 'Journalist.count' do
      post :create, :user => {:email => 'prueba@email.com', :password => '123456', :password_confirmation => '123456', 
        :normas_de_uso => '0'}
    end
    assert_response :success
    assert_template 'journalists/new'
  end
  
  test "should post create okxx" do
    assert_difference 'Journalist.count', +1 do
      post :create, :user => {:email => 'prueba@email.com', :password => '123456', :password_confirmation => '123456', 
        :normas_de_uso => '1', :name => "Nuevo periodista", :last_names => "Last", :media => "http://myblog.com"}
    end
    assert_response :success
    assert_template 'journalists/create'
    assert assigns(:user).status == 'pendiente'
    assert_select 'p', :text => I18n.t('users.Activaremos_cuenta')
  end
  
end
