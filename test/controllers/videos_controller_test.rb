require 'test_helper'

class VideosControllerTest < ActionController::TestCase

  test "should show video in spanish when accessed_directly" do
    get :show, :id => videos(:only_es).id, :locale => 'eu'
    assert_response :success
    assert_select 'div.videos' do 
      assert_select 'h1.title', "Solo castellano eu"
    end
  end
  
  test "should not show draft video" do
    get :show, :id => videos(:draft_video).id
    assert_template 'site/notfound.html'
  end
  
  test "should show index" do
    get :index
    assert_response :success
    
    assert assigns(:featured_video)
    
    assert_select "div.section_main div.section_content div.videos" do
      assert_select "div.featured_video" do
        assert_select 'div.title', :text => "Vídeo destacado"
      end
      assert_select 'div.areas'
      assert_select "div.categories"
    end
  end
  
  test "should get area videos" do
    
    video_for_list = videos(:video_with_event)
    video_for_list.tag_list.add("_a_lehendakaritza")
    video_for_list.save
    
    get :index, :area_id => areas(:a_lehendakaritza).id
    assert assigns(:featured_video)
    assert_equal videos(:every_language), assigns(:featured_video) 
    
    assert assigns(:videos)
    assert assigns(:videos).include?(video_for_list)
    assert !assigns(:videos).include?(videos(:only_es)) # Los que no son del área no salen
    
    assert_select "div.section_main div.section_content div.videos" do
      assert_select 'div.section_heading', :text => 'Destacado'
      assert_select 'div.featured_video.row-fluid', :count => 1 # video destacado
      
      assert_select 'div.grid div.row-fluid div.grid_item', :count => assigns(:videos).length do
        assert_select 'div.span3' do
          assert_select 'div.image'
          assert_select 'div.title'
          assert_select 'div.date'
        end
      end
    end
  end

  test "should get politician videos" do
    video_for_list = videos(:video_with_event)
    video_for_list.tag_list.add(tags(:tag_politician_lehendakaritza).name_es)
    video_for_list.save
    
    get :index, :politician_id => users(:politician_lehendakaritza).id
    assert assigns(:featured_video)
    assert_equal videos(:video_lehendakaritza), assigns(:featured_video)
    assert assigns(:videos)
    
    assert assigns(:videos).include?(video_for_list)
    assert !assigns(:videos).include?(videos(:only_es)) # Los que no son del área no salen
    
    assert_select "div.section_main div.section_content div.videos.index" do
      
      assert_select 'div.section_heading', :text => 'Destacado'
      assert_select 'div.row-fluid', :count => users(:politician_lehendakaritza).videos.length
      
      assert_select 'div.row-fluid div.span3' do
        assert_select 'div.image'
        assert_select 'div.title'
        assert_select 'div.date'
      end
    end
  end
  
  test "should show category by id" do
    get :cat, :id => categories(:cat_de_webtv).id
    assert_response :success
    assert_select 'div.section_content.span8' do
      assert_select 'div.videos' do
        assert_select 'div.section_heading', :text => categories(:cat_de_webtv).name
        assert_select 'div.row-fluid', :count => categories(:cat_de_webtv).videos_count
      end
    end
    assert_select 'div.section_aside.span4' do
      assert_select 'div.aside_module.related_videos.areas div.content ul.categories li', :count => Area.count 
      assert_select 'div.aside_module.related_videos.categories div.content ul.categories li', :count => Video.categories.count
    end
  end
      
  test "should show video" do
    get :show, :id => videos(:every_language).id
    
    assert_response :success
    assert assigns(:video)
    
    assert_select 'div.breadcrumbs' do
      assert_select 'li a', 'Inicio'
      assert_select 'li a', 'Vídeos'
      assert_select 'li a', assigns(:video).title
    end
  end
  
  test "should get video with subtitles and criterio" do
    criterio = criterios(:criterio_for_subtitles)
    video = videos(:video_with_subtitles)
    assert video.update_attribute(:subtitles_es, File.new(File.join(Rails.root, 'test/data', 'test.srt')))
    video.reload                                                                                          
    assert File.exists?("#{Rails.root}/public/uploads/subtitles/#{video.id}/es/test.srt")    
    
    get :show, :id => video.id, :criterio_id => criterio.id
    
    system "rm -r #{Rails.root}/public/uploads/subtitles/#{video.id} > /dev/null"
    assert !File.exists?("#{Rails.root}/public/uploads/subtitles/#{video.id}/es/test.srt")
  end 
  
  test "should track clickthrough when clicking on a search result" do
    assert_content_is_tracked(criterios(:criterio_one), videos(:only_es))
  end
  
  test "should track clickthrough when clicking on a tag item" do
    assert_content_is_tracked(tags(:viajes_oficiales), videos(:only_es))
  end
  
  test "should track clickthrough when clicking on a related_videoxx" do
    assert_content_is_tracked(videos(:video_lehendakaritza), videos(:only_es))
  end
  
end
