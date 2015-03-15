require 'test_helper'

class Admin::External::ItemsControllerTest < ActionController::TestCase
  
  context "as admin" do
    setup do
      login_as("admin")
    end
    
    should "list items for client" do
      get :index, :external_client_id => external_comments_clients(:euskadinet).id
      assert_response :success
      assert assigns(:client)
      assert assigns(:items)
    end
    
  end

end
