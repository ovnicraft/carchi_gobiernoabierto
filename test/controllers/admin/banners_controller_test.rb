require 'test_helper'

class Admin::BannersControllerTest < ActionController::TestCase

  test "should get index" do
    login_as(:admin)
    get :index, :locale => 'es'
    assert_response :success
    assert_template 'admin/banners/index'
    assert_not_nil assigns(@banners)
  end

  test "should get new" do
    login_as(:admin)
    get :new, :locale => 'es'
    assert_response :success
    assert_template 'admin/banners/new'
  end

  test "should create new" do
    login_as("admin")
    assert_difference 'Banner.count', +1 do
      post :create, :locale => 'es', :banner => {:url_es => 'http://www.google.es',
        :alt_es => 'Probando', :logo_es => Rack::Test::UploadedFile.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test-170x100.jpg"), 'image/jpeg')}
    end
    ban=Banner.order('id DESC').first
    assert_equal 'Probando', ban.alt
    assert_response :redirect
    banner_170x100 = File.join(Rails.root, "public", "uploads", "banners", ban.id.to_s, "es", "test-170x100.jpg")
    assert File.exists?(banner_170x100)
    system "rm -r #{File.join(Rails.root, "public", "uploads", "banners", ban.id.to_s)} > /dev/null"
    assert !File.exists?(banner_170x100)
  end

  test "should get edit" do
    login_as("admin")
    get :edit, :locale => 'es', :id => banners(:banner_one).id
    assert_response :success
    assert_template 'admin/banners/edit'
  end

  test "should update" do
    login_as(:admin)
    put :update, :locale => 'es', :id => banners(:banner_one).id, :banner => {:alt_es => 'Nuevo titulo'}
    assert_response :redirect
    ban=Banner.find(banners(:banner_one).id)
    assert_equal 'Nuevo titulo', ban.alt
  end

  test "should destroy js" do
    login_as(:admin)
    assert_difference 'Banner.count', -1 do
      xhr :delete, :destroy, :id => banners(:banner_one).id, :format => 'js'
    end
  end

  test "should destroy" do
    login_as(:admin)
    assert_difference 'Banner.count', -1 do
      delete :destroy, :id => banners(:banner_one).id
    end
    assert_response :redirect
    assert_redirected_to admin_banners_path
  end

end
