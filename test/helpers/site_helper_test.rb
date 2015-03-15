require 'test_helper'
include ERB::Util

class SiteHelperTest < ActionView::TestCase
  context "flv_video_info" do
    setup do
      @document = documents(:news_with_multimedia_dir_and_related_webtv_video_and_gallery_photo)
      prepare_content_for_news_with_multimedia(@document)
      flv_file_name = "test.flv"
      @video_path = "#{@document.multimedia_path}#{flv_file_name.gsub(/\.flv/,'')}"
      @video = videos(:only_es)
      @video.update_attributes(document_id: @document.id, video_path: @video_path)
    end

    teardown do
      clear_multimedia_dir(@document)
      # clean test assets
      if @video_path.present?
        video = @document.webtv_videos.detect {|v| v.video_path.eql?(@video_path)}
        if video.present? && video.subtitles_es.present?
          dirname = File.dirname(video.subtitles_es.path).split('/')[0..-1].join('/')
          assert FileUtils.rm_rf(File.dirname(dirname))
        end
      end
    end

    context "with video path" do
      should "get video info for video and captions in es" do
        video_info = flv_video_info(@video.video_path+".flv", "es")
        assert_equal video_info[:video], File.join(Document::MULTIMEDIA_URL, "#{@video_path}.flv") 
        assert_nil video_info[:captions_url]
      end

      context "with subtitles" do
        setup do
          srt_file = Rack::Test::UploadedFile.new(File.join(Rails.root, "test", "data", "test.srt"), 'text/srt')
          @video.update_attributes(subtitles_es: srt_file)
          assert @video.captions_available?
        end

        should "get video info for video and captions in es" do
          video_info = flv_video_info(@video.video_path+".flv", "es")
          assert_equal video_info[:captions_url], @video.subtitles_es.url
        end

      end
    end


  end

end 
