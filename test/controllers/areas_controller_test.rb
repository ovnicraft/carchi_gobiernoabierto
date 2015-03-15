require 'test_helper'

class AreasControllerTest < ActionController::TestCase

  test "should get index" do
    get :index
    assert_response :success
    assert_template 'index'
    assert assigns(:areas)
  end

  test "should show area activity on show" do
    get :show, :id => areas(:a_lehendakaritza).id
    assert_response :success
    assert_template 'news/index'
  end

  test "should list consejo news" do
    get :show, :id => areas(:a_lehendakaritza).id
    assert assigns(:news).include?(documents(:consejo_news))
  end

  context "featured news" do
    context "without an explicitly set featured news" do
      should "feature newest news item of the area" do
        get :show, :id => areas(:a_lehendakaritza).id
        assert_equal areas(:a_lehendakaritza).news.order('published_at DESC').first, assigns(:leading_news)
      end
    end

    context "with an explicitly set featured news" do
      setup do
        @not_most_recent_news_in_area = documents(:commentable_news)
        @not_most_recent_news_in_area.tag_list.add areas(:a_lehendakaritza).featured_tag_name_es
        assert @not_most_recent_news_in_area.save
      end

      should "feature tagged news althought it is not the most recent" do
        get :show, :id => areas(:a_lehendakaritza).id
        assert_equal @not_most_recent_news_in_area, assigns(:leading_news)
      end
    end
  end
end
