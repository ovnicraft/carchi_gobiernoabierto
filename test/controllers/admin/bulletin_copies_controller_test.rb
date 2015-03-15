require 'test_helper'

class Admin::BulletinCopiesControllerTest < ActionController::TestCase
  def setup
    login_as(:admin)
  end
  
  context "show copy" do
    setup do
      @copy = bulletin_copies(:for_visitante)
      get :show, :id => @copy
    end
    
    should respond_with(:success)
    should render_template("bulletin_mailer/copy")
    should "not increase clickthrough count" do
      assert_no_difference 'Clickthrough.count' do
        get :show, :id => @copy
      end
    end
  end
  
  context "with news with external comments" do
    setup do
      @news_with_external_comments = documents(:commentable_news) 
      @copy = bulletin_copies(:for_visitante_with_news_with_external_comments)
      assert @copy.ordered_user_news.detect {|n| n.id.eql?(@news_with_external_comments.id)}
      get :show, :id => @copy      
    end
    
    should "has correct comments counter" do
      @copy.ordered_user_news.each do |news|
        assert_select "tr.comments_row" do
          assert_select "a.comments_count[href*=\"#{news_url(:id => news.id, :anchor => 'comments')}\"]", :text =>  news.all_comments.count
        end
      end
    end
    
  end
  
end