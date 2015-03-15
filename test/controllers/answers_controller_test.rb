require 'test_helper'

class AnswersControllerTest < ActionController::TestCase
  context "comments" do
    setup do
      @approved_and_official = Comment.create(default_attrs)
      @rejected_and_official = Comment.create(default_attrs)
      @rejected_and_official.update_attribute(:status, 'rechazado')
      @approved_and_not_official = Comment.create(default_attrs.merge(:user => users(:visitante)))
      
      @comment_on_lehendakaritza = comments(:official_comment)
      @comment_on_interior = Comment.create(default_attrs.merge(:commentable => documents(:translated_news)))
    end
    
    context "without context" do
      setup do
        get :index
      end
      
      should "list only official comments" do
        assert assigns(:comments)
        assert_equal [true], assigns(:comments).collect {|c| c.is_official?}.uniq.compact
        assert !assigns(:comments).include?(@approved_and_not_official)
      end
  
      should "list only approved comments" do
        get :index
        assert_equal ['aprobado'], assigns(:comments).collect {|c| c.status}.uniq.compact
        assert !assigns(:comments).include?(@rejected_and_official)
      end
    
      should "list comments of all areas" do
        get :index
        assert assigns(:comments).include?(@comment_on_lehendakaritza)
        assert assigns(:comments).include?(@comment_on_interior)
      end
      
    end
    
    context "with area context" do
      setup do 
        get :index, :area_id => areas(:a_lehendakaritza).id
      end
      
      should "list only official comments" do
        assert assigns(:comments)
        assert_equal [true], assigns(:comments).collect {|c| c.is_official?}.uniq.compact
        assert !assigns(:comments).include?(@approved_and_not_official)
      end
  
      should "list only approved comments" do
        assert_equal ['aprobado'], assigns(:comments).collect {|c| c.status}.uniq.compact
        assert !assigns(:comments).include?(@rejected_and_official)
      end
    
      should "not list comments of other areas" do
        assert assigns(:comments).include?(@comment_on_lehendakaritza)
        assert !assigns(:comments).include?(@comment_on_interior)
      end
      
      should "show not show area filter in answers index" do
        assert_select 'div.filters ul li', :count => 0
      end
    end
  end
  
  context 'xhr' do
    should "return area answers when using the departments filter" do
      lehendakaritza = areas(:a_lehendakaritza)
      xhr :get, :index, :area_id => lehendakaritza.id

      assert assigns(:comments).collect(&:area_id).uniq == [lehendakaritza.id]
      assert_equal 'text/html', @response.content_type
      first_comment = 
      assert_select 'div.filtered_content ul.std_list li.item:first-child div.item_content div.title ', /#{assigns(:comments).first.commentable.title}/
    end
  end
  
  def default_attrs
    {:commentable => documents(:commentable_news), :body => "Comentario oficial", :user => users(:comentador_oficial), :status => 'aprobado'}
  end
end
