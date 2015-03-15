require 'test_helper'

class PoliticiansControllerTest < ActionController::TestCase
  context "with politician" do
    setup do
      @politician = users(:politician_lehendakaritza)
      get :show, :id => @politician.id
    end
    
    should "show activity not show agenda tab" do
      assert_response :success
      assert_template 'news/index'
      
      assert_select 'ul.politician_tabs' do
        assert_select 'li a', :text => 'NOTICIAS'
        assert_select 'li a', :text => 'EVENTOS', :count => 0 # Este político tiene politician_has_agenda == false
        assert_select 'li a', :text => 'VÍDEOS'
      end
    end
    
    should "not show agenda tab" do
      assert_select 'ul.politician_tabs' do
        assert_select 'li', :count => 3
        assert_select 'li a[href=?]', politician_events_path(:politician_id => @politician.id, :anchor => 'middle'), :count => 0
      end
    end
    
    context "featured newsxx" do
      context "without an explicitly set featured news" do
        should "feature newest news item of the area" do
          get :show, :id => @politician.id
          assert_equal @politician.news.listable.order('published_at DESC').first, assigns(:leading_news)
        end
      end

      context "with an explicitly set featured news" do
        setup do
          @not_most_recent_news_for_politician = documents(:commentable_news)
          @not_most_recent_news_for_politician.tag_list.add @politician.featured_tag_name_es
          assert @not_most_recent_news_for_politician.save
        end

        should "feature tagged news althought it is not the most recent" do
          get :show, :id => @politician.id
          assert_equal @not_most_recent_news_for_politician, assigns(:leading_news)
        end
      end
    end
    
    
  end
  
  context "politician with agenda" do
    setup do
      @politician = users(:politician_lehendakaritza)
      @politician.update_attribute(:politician_has_agenda, true)
      get :show, :id => @politician.id
    end
    
    should "show ageda tab" do
      assert_select 'ul.politician_tabs' do
        assert_select 'li', :count => 4
        assert_select 'li a[href=?]', politician_events_path(:politician_id => @politician.to_param, :anchor => 'middle')
        
        assert_select 'li a', :text => 'NOTICIAS'
        assert_select 'li a', :text => 'EVENTOS'
        assert_select 'li a', :text => 'VÍDEOS'        
      end
      
    end
    
    
  end
  
  context "with banned politician" do
    setup do
      @politician = users(:politician_interior_vetado)
    end
    
    should "not show activity" do
      get :show, :id => @politician.id
      assert_response :not_found
      assert_template 'site/notfound.html'
    end
    
  end
  
  context "with logged in politician" do
    setup do
      @politician = users(:politician_lehendakaritza)      
      login_as(:politician_lehendakaritza)
    end
    
    should "show politician page without 'haz una pregunta' link" do
      get :show, :id => @politician.id
      assert_response :success
      
      assert_select 'a#question-popover', :count => 0
    end

    should "show other politician page with 'haz una pregunta' link" do
      get :show, :id => users(:politician_one)
      assert_response :success
      
      # Temporalmente lo desactivamos (ticket #3673)
      assert_select 'a#question-popover', :count => 0
    end
  end
  
end
