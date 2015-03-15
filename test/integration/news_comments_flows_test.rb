require 'test_helper'

class NewsCommentsFlowsTest < ActionDispatch::IntegrationTest
  fixtures :all


  test "anonymous user's comment" do
    get "/es/news/#{documents(:commentable_news).id}"
    assert_response :success

    init_comments_count = assigns(:document).comments.approved.count
    ExternalComments::Item.where(:irekia_news_id => assigns(:document).id).each do |item| 
      init_comments_count += item.comments.count
    end
    
    assert_select 'div.comments' do 
      assert_select 'ul li.clearfix', :count => init_comments_count + 1
      assert_select 'ul li.clearfix div.item_content', /aprobado/
    end

    assert_select 'div.comments li.form div.item_content' do
      assert_select 'form[action=?]', '/es/comments'
      assert_select 'div.textarea-comment' do
        assert_select 'span.holder', /algo que decir/i
        assert_select 'textarea[name=?]', 'comment[body]'
      end
    end
    
    # No puedo hacer comentarios anonimos
    post_via_redirect comments_path(:news_id => documents(:commentable_news).id, :comment => {:body => ''})
    assert_equal new_session_path, path
    
    return_to = news_path(:id => documents(:commentable_news).id, :locale => 'es')
    get new_session_path(:return_to => return_to)
    # Login incorrecto
    post_via_redirect session_path, :email => users(:visitante).email, :password => "wrong", :return_to => return_to # no deberia necesitar el return_to (?)
    assert_template "new"
    
    # Login correcto
    post_via_redirect session_path, :email => users(:visitante).email, :password => 'test', :return_to => return_to # no deberia necesitar el return_to (?)
    assert_equal return_to, path

    # Comentario sin texto, no entra
    post_via_redirect comments_path(:news_id => documents(:commentable_news).id, :comment => {:body => ''})
    # assert assigns(:comment)
    # assert_equal "no puede estar vacío", assigns(:comment).errors[:body]
    assert_equal news_path(documents(:commentable_news)), path
    assert_match "no puede estar vacío", flash[:error]
    
    # Comentario con texto
    post_via_redirect comments_path(:news_id => documents(:commentable_news).id, :comment => {:body => "comentario", :name => users(:visitante).name})
    assert_equal news_path(documents(:commentable_news), locale: 'es'), path
    assert_equal '¡Gracias por tu comentario! La persona moderadora lo publicará en breve.', flash[:notice] 
    assert_select 'div.comments' do 
      assert_select 'ul li.clearfix', init_comments_count + 1 # el comentario no sale antes de moderarlo
    end
    
  end
  
  test "admin's comment" do
    news = documents(:commentable_news)
    get "/es/news/#{news.id}"
    assert_response :success
    
    init_comments_count = assigns(:document).comments.approved.count
    ExternalComments::Item.where(:irekia_news_id => news.id).each do |item| 
      init_comments_count += item.comments.count
    end

    assert_select 'div.comments' do 
      assert_select 'ul li.clearfix', :count => init_comments_count + 1
    end
    
    return_to = news_path(:id => documents(:commentable_news).id, :locale => 'es')
    get new_session_path(:return_to => return_to)
    
    # Login correcto
    post_via_redirect session_path, :email => users(:admin).email, :password => 'test', :return_to => return_to # no deberia necesitar el return_to (?)
    assert_equal return_to, path
    
    # Comentario con texto
    post_via_redirect comments_path(:news_id => documents(:commentable_news).id, :comment => {:body => "comentario", :name => users(:visitante).name})
    assert_equal news_path(documents(:commentable_news)), path
    assert_equal 'Tu comentario se ha publicado correctamente.', flash[:notice] 
    assert_select 'div.comments' do 
      assert_select 'ul li.clearfix', init_comments_count + 2
    end
  end

end
