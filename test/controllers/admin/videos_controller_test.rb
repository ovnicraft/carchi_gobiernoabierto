require 'test_helper'

class Admin::VideosControllerTest < ActionController::TestCase
  
  test "unlogged user should not be redirected" do
    get :index
    assert_not_authorized
  end
  
  ["admin", "colaborador"].each do |role|
    test "show if logged as #{role}" do
      login_as(role)
      get :index
      assert_response :success
      assert_template "index"
    end
  end
  
  roles = ["periodista", "visitante", "comentador_oficial", "secretaria_interior", "jefe_de_gabinete", "jefe_de_prensa", "miembro_que_modifica_noticias", "room_manager"]
  roles << "operador_de_streaming" if Settings.optional_modules.streaming
  roles.each do |role|
     test "redirect if logged as #{role}" do
       login_as(role)
       get :index
       assert_not_authorized     
     end     
  end
  
  test "should get index" do
    login_as(:admin)
    get :index
    assert_response :success
    assert_template "index"
  end
  
  # Subtitles
  
  test "should not upload subtitles if no document is present" do
    login_as(:admin)
    video = videos(:only_es)
    # file = File.new(File.join(Rails.root, "test", "data", "test.srt"))
    file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.srt"), 'text/srt')
    
    assert_nil video.document_id
    
    post :update_subtitles, :id => video.id, :locale => 'es', :subtitles_es => file
    assert_response :redirect
    assert_redirected_to admin_video_path(video)
  end

  test "should upload subtitles if video belongs to document" do
    login_as(:admin)
    video = videos(:only_es)
    file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.srt"), 'text/srt')
    document = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    
    video.update_attribute(:document_id, document.id)
    assert_not_nil video.document_id
    
    assert !video.subtitles_es.exists?
    
    post :update_subtitles, :id => video.id, :locale => 'es', :video => {:subtitles_es => file}
    assert_response :redirect
    assert_redirected_to sadmin_news_subtitles_path(:news_id => document.id)
    
    video.reload
    assert video.subtitles_es.exists?

    # clean test assets
    dirname = File.dirname(video.subtitles_es.path).split('/')[0..-1].join('/')
    assert FileUtils.rm_rf(File.dirname(dirname))
  end

  test "should delete subtitles for a specific language" do
    login_as(:admin)
    video = videos(:only_es)
    file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.srt"), 'text/srt')
    document = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    
    video.update_attributes(:document_id => document.id, :subtitles_es => file)
    assert video.subtitles_es.exists?
    
    post :delete_subtitles, :id => video.id, :locale => 'es', :lang => "es"
    assert_response :redirect
    assert_redirected_to sadmin_news_subtitles_path(:news_id => document.id)
    
    video.reload
    assert !video.subtitles_es.exists?
  end

  test "should upload subtitles and create video if document and flv are given" do
    login_as(:admin)
    srt_file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.srt"), 'text/srt')
    document = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    prepare_content_for_news_with_multimedia(document)
    
    flv_file_name = "test.flv"
    flv_url = File.join(Document::MULTIMEDIA_URL, document.multimedia_path, flv_file_name)
    video_path = "#{document.multimedia_path}#{flv_file_name.gsub(/\.flv/,'')}"
    
    assert_equal "#{document.multimedia_path}#{flv_file_name}", document.videos[:featured][:es]
    assert !Video.find_by_video_path(video_path)
    assert_nil document.webtv_videos.detect {|v| v.video_path.eql?(video_path)}
   
    assert_difference("Video.count", 1) do
      post :create_with_subtitles, :locale => 'es', :video => {:document_id => document.id, :flv_url => flv_url, :subtitles_es => srt_file}
    end
    assert_response :redirect
    assert_redirected_to sadmin_news_subtitles_path(:news_id => document.id)
    
    document.reload
    assert document.webtv_videos.detect {|v| v.video_path.eql?(video_path)}
    assert document.webtv_videos.detect {|v| v.video_path.eql?(video_path)}.subtitles_es.exists?
    
    clear_multimedia_dir(document)
    # clean test assets
    video = document.webtv_videos.detect {|v| v.video_path.eql?(video_path)}
    dirname = File.dirname(video.subtitles_es.path).split('/')[0..-1].join('/')
    assert FileUtils.rm_rf(File.dirname(dirname))
  end
  
end
