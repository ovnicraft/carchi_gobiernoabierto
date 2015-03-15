require 'test_helper'

class Admin::SorganizationsControllerTest < ActionController::TestCase
  
  test "should get index departments" do
    login_as('admin')
    get :index, :locale => 'es'
    assert_response :success
    assert_template 'admin/sorganizations/departments'
    assert_select "h1", :text => /Redes Sociales/
    assert_select "ul.categories li", :text => /Presidencia/
  end
  
  # test "should not get index" do
  #   get :index, :locale => 'es'
  #   assert_response :redirect
  #   assert_redirected_to login_url
  # end
  
  test "should get index sorganizations" do
    login_as('admin')
    dept=organizations(:lehendakaritza)
    get :index, :locale => 'es', :dept_id => dept.id
    assert_response :success
    assert_template 'admin/sorganizations/index'
    assert_select "div.sorganizations ul.snetworks li", :text => /Irekia/i
  end
  
  test "should get new" do
    login_as('admin')
    dept=organizations(:lehendakaritza)
    get :new, :locale => 'es', :dept_id => dept.id
    assert_response :success
    assert_template 'admin/sorganizations/new'
    assert_select "table.admin tr td", :text => /Presidencia/
  end
  
  test "should create new" do
    login_as('admin')
    dept=organizations(:lehendakaritza)
    assert_difference 'Sorganization.count', +1 do 
      assert_difference 'Snetwork.count', +2 do 
        post :create, :locale => 'es', :dept_id => dept.id, :sorganization => {:name_es => 'Emakunde', 
                    :name_eu => 'Emakunde', :new_snetworks_attributes => {'0' => {:url => 'http://twitter.com/emakunde', :position => 1}, 
                                                                      '1' => {:url => 'http://facebook.com/emakunde', :position => 2}}}
      end                                                                
    end  
    assert_response :redirect
    assert_redirected_to admin_sorganizations_url(:dept_id => dept.id)
  end
 
  test "should create new with valid icon" do
    login_as('admin')
    dept=organizations(:lehendakaritza)
    assert_difference 'Sorganization.count', +1 do 
      assert_difference 'Snetwork.count', +2 do 
        post :create, :locale => 'es', :dept_id => dept.id, :sorganization => {:name_es => 'Emakunde', 
                    :name_eu => 'Emakunde', 
                    :icon => Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "sorganization_valid_icon.png"), 'image/png'),
                    :new_snetworks_attributes => {'0' => {:url => 'http://twitter.com/emakunde', :position => 1}, 
                                                  '1' => {:url => 'http://facebook.com/emakunde', :position => 2}}}
      end                                                                
    end  
    assert_response :redirect
    assert_redirected_to admin_sorganizations_url(:dept_id => dept.id)
  end
 
  test "should not create new" do
    login_as('admin')
    dept=organizations(:lehendakaritza)
    assert_no_difference 'Sorganization.count' do 
      assert_no_difference 'Snetwork.count' do 
        post :create, :locale => 'es', :dept_id => dept.id, :sorganization => {
        :new_snetworks_attributes => {'0' => {:url => 'twitter.com/emakunde', :position => 1}, '1' => {:url => 'facebook.com/emakunde', :position => 2}}}
      end                                                                
    end  
    assert_template 'admin/sorganizations/new'
    assert_select "div.errorExplanation ul li", :text => /no puede estar vacío/
  end

  test "should not create new with invalid icon" do
    login_as('admin')
    dept=organizations(:lehendakaritza)
    assert_no_difference 'Sorganization.count' do 
      assert_no_difference 'Snetwork.count' do 
        post :create, :locale => 'es', :dept_id => dept.id, :sorganization => {:name_es => 'Emakunde', 
                    :name_eu => 'Emakunde', 
                    :icon => Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "sorganization_invalid_icon.png"), 'image/png'),
                    :new_snetworks_attributes => {'0' => {:url => 'http://twitter.com/emakunde', :position => 1}, 
                                                  '1' => {:url => 'http://facebook.com/emakunde', :position => 2}}}
      end                                                                
    end  
    assert_template 'admin/sorganizations/new'
    assert_select "div.errorExplanation ul li", :text => /debe tener un tamaño de 39x39px/
  end
   
  test "should get edit" do
    login_as('admin')
    sorg=sorganizations(:social_org)
    get :edit, :locale => 'es', :id => sorg.id
    assert_response :success
    assert_template 'admin/sorganizations/edit'
    assert_select "table.admin tr input#sorganization_name_es", :value => "Irekia"
  end
  
  test "should update delete old" do
    login_as('admin')
    sorg=sorganizations(:social_org)
    snet1=Snetwork.find_by_url('http://twitter.com/irekia')
    snet2=Snetwork.find_by_url('http://facebook.com/irekia')    
    assert_difference 'Snetwork.count', -1 do
      put :update, :locale => 'es', :dept_id => sorg.department_id, :id => sorg.id, :sorganization => {:existing_snetworks_attributes => 
                                {snet1.id.to_s => {:url => 'http://twitter.com/irekia', :deleted => 1}, snet2.id.to_s => {:url => 'http://facebook.com/irekia'}}}
    end  
    assert_response :redirect
    assert_redirected_to admin_sorganizations_url(:dept_id => sorg.department_id)
  end
  
  test "should update new and old" do
    login_as('admin')
    sorg=sorganizations(:social_org)
    snet1=Snetwork.find_by_url('http://twitter.com/irekia')
    snet2=Snetwork.find_by_url('http://facebook.com/irekia')
    assert_no_difference 'Snetwork.count' do
      put :update, :locale => 'es', :dept_id => sorg.department_id, :id => sorg.id, :sorganization => 
      {:existing_snetworks_attributes => {snet1.id.to_s => {:url => 'http://twitter.com/irekia', :position => 1}, 
                            snet2.id.to_s => {:url => 'http://facebook.com/irekia', :deleted => '1', :position => 2} },
                            :new_snetworks_attributes => {'1' => {:url => 'http://slideshare.com', :position => 3}}}
    end   
    assert_response :redirect
    assert_redirected_to admin_sorganizations_url(:dept_id => sorg.department_id)
  end
  
  test "should destroy" do
    login_as('admin')
    sorg=sorganizations(:social_org)
    dept_id=sorg.department_id
    assert_difference 'Snetwork.count', -2 do
      assert_difference 'Sorganization.count', -1 do
        delete :destroy, :locale => 'es', :id => sorg.id    
      end
    end  
    assert_response :redirect 
    assert_redirected_to admin_sorganizations_url(:dept_id => dept_id)
  end  
  
end  
