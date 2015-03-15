require 'test_helper'

class Admin::AreasControllerTest < ActionController::TestCase
  def setup
    login_as('admin')
    ActionMailer::Base.deliveries = []
  end
  
  context "existing area" do
    setup do
      @area = areas(:a_lehendakaritza)
    end
    
    should "show area" do
      get :show, :id => @area.id
      assert_response :success
    end

    should "edit area" do
      get :edit, :id => @area.id
      assert_response :success
    end
    
    should "update area" do
      put :update, :id => @area.id,  :area => {:name_es => "Nombre nuevo", :name_eu => "Izen berria", :name_en => "New name"}
      assert_response :redirect
      
      assert assigns(:area)
      assert_equal "Nombre nuevo", assigns(:area).name_es
    end
    
  end
end
