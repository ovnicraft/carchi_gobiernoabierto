require 'test_helper'

class Sadmin::SubtitlesControllerTest < ActionController::TestCase

  context "admin access" do  
    setup do
      login_as(:admin)
      @news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
    end

    should "accesss subtitles" do
      get :index, :news_id => @news.id
      assert_response :success

      assert_select "p", text: "No hay vídeos para este idioma", count: 3 # es, eu, en
    end

    context "with subtitles" do
      setup do
        prepare_content_for_news_with_multimedia(@news)
        flv_file_name = "test.flv"
        @video_path = "#{@news.multimedia_path}#{flv_file_name.gsub(/\.flv/,'')}"

        srt_file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.srt"), 'text/srt')


        @video = videos(:only_es)
        @video.update_attributes(document_id: @news.id, video_path: @video_path, subtitles_es: srt_file)
        assert @video.captions_available?
        assert_equal @video.document, @news
        assert_equal "#{@video.video_path}.flv", @news.videos[:featured][:es]
      end

      teardown do
        clear_multimedia_dir(@news)
        # clean test assets
        if @video_path.present?
          video = @news.webtv_videos.detect {|v| v.video_path.eql?(@video_path)}
          if video.present?
            dirname = File.dirname(video.subtitles_es.path).split('/')[0..-1].join('/')
            assert FileUtils.rm_rf(File.dirname(dirname))
          end
        end
      end



      should "show subtitles filename" do
        get :index, :news_id => @news.id
        assert assigns(:videos)[:es].present?

        assert_select "p", text: "No hay vídeos para este idioma", count: 2 # eu, en

        assert_select "li", text: /sustituir/i 
      end


    end
  end
  
  ["jefe_de_prensa", "jefe_de_gabinete", "colaborador", "miembro_que_modifica_noticias"].each do |role|
    test "#{role} can not accesss subtitles" do
      login_as(role)
      news = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)

      get :index, :news_id => news.id
      assert_response :redirect
      
      # access_denied
      assert_redirected_to new_session_path()
    end
    
  end
  
end
