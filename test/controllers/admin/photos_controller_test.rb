require 'test_helper'

class Admin::PhotosControllerTest < ActionController::TestCase

  test "redirect if not logged" do
    get :new
    assert_not_authorized
  end

  ["admin", "colaborador"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :show, :id => photos(:photo_one).id, :album_id => albums(:album_one).id
      assert_response :success
      assert_template "show"
    end
  end

  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", \
   "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :show, :id => photos(:photo_one).id, :album_id => albums(:album_one).id
       assert_not_authorized
     end
  end


  test "import fotos in new album" do
    login_as("admin")

    n_photos_in_dir = Dir.glob(File.join(Photo::PHOTOS_PATH, "photos", "*.jpg")).length

    assert_equal 6, Photo.count

    assert_difference 'Album.count', +1 do
      post :create, :photo => {:title_es => "Prueba", :title_eu => "Prueba", :title_en => "Prueba"}, :dir_path => "photos/", :album_id => 0
    end
    assert_response :success

    assert assigns(:album)
    assert_equal n_photos_in_dir, assigns(:album).photos.count
    assert_equal 6+n_photos_in_dir, Photo.count

    assert File.exists?(File.join(Photo::PHOTOS_PATH, "photos", "n136"))
    assert_equal n_photos_in_dir, Dir.glob(File.join(Photo::PHOTOS_PATH, "photos", "n136", "*.jpg")).length

    assert_template "create"

    assert_select 'span#found_files_counter', 1
    assert_select 'span#imported_files_counter', 1

    delete_generated_thumbnails
  end

  test "import photos in existing album" do
    login_as("admin")
    n_photos_in_dir = Dir.glob(File.join(Photo::PHOTOS_PATH, "photos", "*.jpg")).length

    assert_equal 6, Photo.count

    assert_equal 1, albums(:album_one).album_photos.count
    assert_no_difference 'Album.count' do
      post :create, :photo => {:title_es => "Prueba", :title_eu => "Prueba", :title_en => "Prueba"}, :dir_path => "photos/", :album_id => albums(:album_one).id
    end
    assert_response :success

    assert assigns(:album)
    assert_equal 1 + n_photos_in_dir, assigns(:album).photos.count
    assert_equal 6 + n_photos_in_dir, Photo.count

    assert File.exists?(File.join(Photo::PHOTOS_PATH, "photos", "n136"))
    assert_equal n_photos_in_dir, Dir.glob(File.join(Photo::PHOTOS_PATH, "photos", "n136", "*.jpg")).length

    assert_template "create"

    assert_select 'span#found_files_counter', 1
    assert_select 'span#imported_files_counter', 1

    delete_generated_thumbnails
  end

  test "fail if empty dir_path" do
    login_as("admin")
    post :create, :photo => {:title_es => ""}, :dir_path => ""
    assert_response :success
    assert_template "new"
    assert_equal ["No ha indicado ningún directorio"], assigns(:photo).errors[:base]
  end

  def delete_generated_thumbnails
    Tools::Multimedia::PHOTOS_SIZES.keys.each do |size|
      FileUtils.rm_rf(Dir.glob(File.join(Photo::PHOTOS_PATH, "photos", size.to_s)))
    end
  end
end
