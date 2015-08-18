require 'test_helper'

class DebatesControllerTest < ActionController::TestCase
 if Settings.optional_modules.debates
  should "index published and translated debates" do
    get :index, :locale => 'eu'
    assert !assigns(:debates).include?(debates(:debate_sin_publicar))
    assert assigns(:debates).include?(debates(:debate_sin_traducir))
  end

  context "rss" do
    should "news index" do
      get :index, :format => 'rss'
      assert_response :success
      
      assert_equal I18n.t('debates.feed_title', :name => Settings.site_name), assigns(:feed_title)
      assert_template 'debates/index', format: :rss
    end

    should "only news from this area index" do
      get :index, :area_id => areas(:a_lehendakaritza).id, :format => 'rss'
      assert_response :success
      
      assert_equal I18n.t('debates.feed_title', :name => "Lehendakaritza"), assigns(:feed_title)
      assert_template 'debates/index', format: :rss
      assert assigns(:debates).collect(&:area_id).uniq == [areas(:a_lehendakaritza).id]
    end
  end

  should "show debate redirects to current stage" do
    debate = debates(:debate_completo)
    get :show, :id => debate.id
    assert_redirected_to(debate_path(:id => debate.id, :stage => debate.current_stage.label))
  end

  should "show debate" do
    debate = debates(:debate_completo)
    get :show, :id => debate.id, :stage => debate.current_stage.label
    assert_template 'debates/show', 'debates/conclusion' 
    assert assigns(:stage), debate_stages(:debate_completo_conclusions)
  end

  should "not show unpublished debate" do
    debate = debates(:debate_sin_publicar)
    get :show, :id => debate.id
    assert_template 'site/notfound.html'
  end

  DebateStage::STAGES.each do |stage| 
    should "show debate #{stage}" do
      debate = debates(:debate_completo)
      get :show, :locale => 'es', :id => debate.id, :stage => stage.to_s
      assert_template 'debates/show', "debates/#{stage}"    
      assert assigns(:stage), debate_stages("debate_completo_#{stage}".to_sym)
      
      if stage.eql?(:presentation)
        assert_select "div.section_heading", I18n.t('debates.body_title')
      end
    end
  end

  # FUTURE
  should "show future presentation" do
    get :show, :id => debates(:debate_nuevo), :stage => 'presentation'
    assert_template 'debates/show', 'debates/presentation'
  end

  ['discussion', 'contribution', 'conclusions'].each do |stage|
    should "not show future #{stage}" do
      get :show, :id => debates(:debate_nuevo), :stage => stage
      assert_template 'debates/show'
      assert_select "div.is_future", I18n.t('debates.is_future', :stage => I18n.t("debates.stage_#{stage}"), :date => I18n.l(debate_stages("debate_nuevo_#{stage}").starts_on.to_date, :format => :long))
    end
  end

  # PASSED
  should "show discussion with participation closed" do
    get :show, :id => debates(:debate_completo), :stage => 'discussion'
    assert_template 'debates/show', 'debates/discussion'
    # votes disabled
    assert_select "form.vote.against input[type=submit][disabled=?]", 'disabled'
    assert_select "div.votes div.stage_closed", I18n.t("debates.is_passed", :stage => I18n.t("debates.stage_discussion"))
    # arguments disabled
    assert_select "div.arguments form", false
    assert_select "div.arguments div.stage_closed", I18n.t("debates.is_passed", :stage => I18n.t("debates.stage_discussion"))
    # comments disabled
    assert_select "div.comments li.item.form", false
    assert_select "div.comments span.comments_closed", I18n.t('comments.comentarios_cerrados')
  end

  should "show contribution not prepared" do
    debate = debates(:debate_completo)
    assert debate.update_attribute(:page_id, nil)
    get :show, :id => debate.id, :stage => 'contribution'
    assert_template 'debates/show', 'debates/contribution'
    assert !assigns(:page)
    assert_select 'div.currently_working', I18n.t('debates.currently_working')
  end

  should "show conclusions not prepared" do
    debate = debates(:debate_completo)
    assert debate.update_attribute(:news_id, nil)
    get :show, :id => debate.id, :stage => 'conclusions'
    assert_template 'debates/show', 'debates/conclusions'
    assert !assigns(:news)
    assert_select 'div.currently_working', I18n.t('debates.currently_working')
  end
  
  context "without context" do
    setup do
      get :index
    end
    
    should "list only published debates" do
      get :index
      assert_equal [true], assigns(:debates).collect {|c| c.published?}.uniq.compact
      assert !assigns(:debates).include?(debates(:debate_sin_publicar))
    end
  
    should "list debates of all areas" do
      get :index
      assert assigns(:debates).include?(debates(:debate_nuevo))
      assert assigns(:debates).include?(debates(:debate_sin_traducir))
    end
    
    should "show show area filter in debates index" do
      assert_select 'div.filters'
    end
  end
  
  
  context "with area context" do
    setup do 
      get :index, :area_id => areas(:a_lehendakaritza).id
    end

    should "list only published debates" do
      assert_equal [true], assigns(:debates).collect {|c| c.published?}.uniq.compact
      assert !assigns(:debates).include?(debates(:debate_sin_publicar))
    end
  
    should "not list debates of other areas" do
      assert assigns(:debates).include?(debates(:debate_nuevo))
      assert !assigns(:debates).include?(debates(:debate_sin_traducir))
    end
    
    should "show not show area filter in debates index" do
      assert_select 'div.filters', :count => 0
    end
  end
  
  context 'xhr' do
    should "return area debates when using the departments filter" do
      lehendakaritza = areas(:a_lehendakaritza)
      xhr :get, :index, :area_id => lehendakaritza.id

      assert assigns(:debates).collect(&:area_id).uniq == [lehendakaritza.id]
      assert_equal 'text/html', @response.content_type
      assert_select 'div.filtered_content div.grid div.row-fluid div.grid_item div.title a[href=?] ', debate_path(assigns(:debates).first)
    end
  end
  
  
  context "featured news" do
    setup do
      @debate = debates(:debate_completo)
      
      @not_most_recent_news_in_debate = documents(:translated_news)
      @not_most_recent_news_in_debate.tag_list.add @debate.hashtag
      @not_most_recent_news_in_debate.save
      
      @most_recent_news_in_debate = documents(:published_news)
      @most_recent_news_in_debate.tag_list.add @debate.hashtag
      @most_recent_news_in_debate.save
    end
    
    context "without an explicitly set featured news" do
      should "feature newest news item of the area" do
        get :show, :id => @debate.id, :stage => 'presentation'
        assert_equal @debate.related_news.first, assigns(:leading_news)
        assert_equal @most_recent_news_in_debate, assigns(:leading_news)
      end
    end
    
    context "with an explicitly set featured newsxx" do
      setup do
        @not_most_recent_news_in_debate.tag_list.add @debate.featured_tag_name_es
        assert @not_most_recent_news_in_debate.save
      end
      
      should "feature tagged news althought it is not the most recent" do
        get :show, :id => @debate.id, :stage => 'presentation'
        assert_equal @not_most_recent_news_in_debate, assigns(:leading_news)
      end
    end
  end

  test "should track clickthrough when clicking on a search result" do
    assert_content_is_tracked(criterios(:criterio_one), debates(:debate_completo))
  end
  
  test "should track clickthrough when clicking on a tag item" do
    assert_content_is_tracked(tags(:viajes_oficiales), debates(:debate_completo))
  end  
 end
end
