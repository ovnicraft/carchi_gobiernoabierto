require 'test_helper'

class Admin::External::ClientsControllerTest < ActionController::TestCase

  context "as admin" do
    setup do
      login_as("admin")
    end
    
    should "show index of external comments clients" do
      get :index
      assert_response :success
      
      assert assigns(:clients)
    end
    
    should "create new client" do
      assert_difference "ExternalComments::Client.count", 1 do
        post :create, :client => {:name => "Zuzenean", :url => "www.zuzenean.euskadi.net", :code => "s68", :organization_id => organizations(:lehendakaritza).id}
      end
      assert_response :redirect
      assert_redirected_to admin_external_client_path(assigns(:client))
    end
    
    should "show client" do
      get :show, :id => external_comments_clients(:euskadinet).id
      assert_response :success
    end

    should "edit client" do
      get :edit, :id => external_comments_clients(:euskadinet).id
      assert_response :success
    end

    should "update client" do
      client = external_comments_clients(:euskadinet)
      new_data = {:name => "Web de euskadi.net", 
                  :url => "www.euskadi.net", 
                  :code => "new_code", 
                  :organization_id => organizations(:gobierno_vasco).id}
      put :update, :id => client.id, :client => new_data
      
      assert_response :redirect
      
      client.reload
      new_data.keys.each do |key|
        assert_equal new_data[key], client.send(key)
      end
      
    end
    
    should "destoy client without items" do
      client = external_comments_clients(:cliente_sin_paginas)
      assert_difference "ExternalComments::Client.count", -1 do
        delete :destroy, :id => client.id
      end
      assert_response :redirect
      assert_redirected_to admin_external_clients_path()
    end

    should "not destoy client with items" do
      client = external_comments_clients(:euskadinet)
      assert_no_difference "ExternalComments::Client.count" do
        delete :destroy, :id => client.id
      end
      assert_response :redirect
      assert_redirected_to admin_external_client_path(client)
    end
    
  end
end
