require 'test_helper'

class Admin::OutsideOrganizationsControllerTest < ActionController::TestCase
 if Settings.optional_modules.debates
  def setup 
    login_as('admin')
  end

  def teardown
    # @organization.remove_logo!
    FileUtils.rm_rf(Dir["#{Rails.root}/test/uploads/outside_organization"])
  end

  context "list" do
    setup do
      get :index
    end

    should "respond with success" do
      assert_response :success
    end
    
    should "show create debate link" do
      assert_select "ul.edit_links li a", :text => "Añadir entidad"
    end

    should "show submenu with Entidades tab" do
      assert_select "div.submenu" do
        assert_select "ul" do
          assert_select "li", :count => 3
          assert_select "li a", :text => "Propuestas"        
          assert_select "li a", :text => "Argumentos"
          assert_select "li", :text => "Entidades"          
        end
      end
    end
  end
  
  context "new organization" do
    should "get new" do
      get :new
      assert_response :success
    end
    
    should "create organization" do
      assert_difference "OutsideOrganization.count", 1 do
        post :create, :outside_organization => {"name_es"=>"Nueva entidad relacionada sin logo"}
      end
      assert_response :redirect
      assert_redirected_to admin_outside_organizations_path
    end
    
    should "not create organization without name_es" do
      assert_no_difference "OutsideOrganization.count" do
        post :create, :outside_organization => {"name_eu"=>"Nueva entidad relacionada sin logo"}
      end
      assert_response :success
    end    
  end
  
  context "existing organization" do
    setup do
      @org = outside_organizations(:organization_for_debate)
    end
    
    should "get edit" do
      get :edit, :id => @org.id
      assert_response :success
    end
    
    should "update organization" do
      put :update, :id => @org.id, :outside_organization => {"name_es"=>"Entidad", "name_eu"=>"Entidad EU", "name_en"=>"Entity",      
                                                    "logo"=> File.new(File.join(Rails.root, 'test/data/photos', 'test70x70.png'))}
      assert_response :redirect
    end
    
    should "destroy organization" do
      assert_difference "OutsideOrganization.count", -1 do
        delete :destroy, :id => @org.id
      end
      assert_response :redirect
    end
  end
 end
end
