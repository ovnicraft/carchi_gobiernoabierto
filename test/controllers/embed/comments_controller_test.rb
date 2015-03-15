require 'test_helper'

class Embed::CommentsControllerTest < ActionController::TestCase
  context "with external client" do
    setup do
      @client = external_comments_clients(:euskadinet)
    end
    
    context "with external item" do
      setup do
        @item = external_comments_items(:euskadinet_item1)
      end
        
      should "show comments" do 
        get :show, :url => @item.url, :client => @client.code
        assert_response :success
        assert_template layout: 'embed'
      end
    end
    
    context "new external item" do
      setup do
        @new_url = "http://www.euskadi.net/r33-2288/es/contenidos/noticia/130829_seguridad_movil/es_sll/informacion.html"
        @new_title = "Recomendaciones de seguridad para el uso de Internet en el teléfono móvil"
      end
      
      should "create commentable item if not exists" do
        assert_difference "ExternalComments::Item.count", 1 do
          get :show, :url => @new_url, :client => @client.code, :title => @new_title
        end
        last_item = ExternalComments::Item.last
        assert_equal @new_url, last_item.url
        assert_equal @new_title, last_item.title
      end
      
      context "show comments" do
        should "show comments" do 
          get :show, :url => @new_url, :client => @client.code
          assert_response :success
        end
      end
    end
    
    context "empty url" do
      should "return service not available if url is blank" do
        assert_no_difference "ExternalComments::Item.count" do
          get :show, :url => "", :client => @client.code
        end
      end
    end
  end
  
  context "with invalid client id" do
    should "render nothing" do
      get :show, :url => "url", :client => "-1", :title => "title"
      assert_response :success
      assert @response.body.gsub(/\s/,'').empty?
    end
  end

  context "with commentable news" do
    setup do
      @client = external_comments_clients(:euskadinet)
      @item = external_comments_items(:euskadinet_item_commentable_irekia_news)
      @irekia_news = documents(:commentable_news) 
      
      assert_equal @irekia_news.id, @item.irekia_news_id
      
      get :show, :url => @item.url, :news_id => @irekia_news.id
    end

    should "render embed layout" do
      assert_response :success
      assert_template layout: 'embed'
    end
    
    should "show comments from irekia and external client" do
      assert assigns(:comments)
      
      @irekia_news.comments.approved.each do |comment|
        assert assigns(:comments).detect {|c| c.eql?(comment)}
      end
      
      @item.comments.approved.each do |comment|
        assert assigns(:comments).detect {|c| c.eql?(comment)}
      end
    end
  end
  

  context "with irekia_news_id" do
    setup do
      @client = external_comments_clients(:euskadinet)
      @irekia_news = documents(:one_news)
    end
    
    context "new item" do
      context "for existing client" do
        setup do
          @item_url = "http://#{@client.url}/noticia_de_irekia.html"
          get :show, :url => @item_url, :news_id => @irekia_news.id
        end
        
        should "render embed layout" do
          assert_response :success
          assert_template layout: 'embed'
        end
        
        context "with non-utf title" do
          setup do
            @item_title = "Título en latin1".encode("gbk", "utf-8").first
            assert !@item_title.is_utf8?
            get :show, :url => @item_url, :news_id => @irekia_news.id, :title => @item_title
          end

          should "render embed layout" do
            assert_response :success
            assert_template layout: 'embed'
          end
        end

        context "with empty url should render nothing and send exception notification" do
          setup do
            @item_url = nil
            @item_title = "Página sin URL"
            assert_difference 'ActionMailer::Base.deliveries.size', + 1 do
              get :show, :url => @item_url, :news_id => @irekia_news.id, :title => @item_title
            end
          end

          should "render nothing" do
            assert_response 503
            assert_template layout: nil
          end
          
          should "send email with the error" do
            m = ActionMailer::Base.deliveries.last
            assert_match /error/i, m.subject
          end
        end
        
      end
    
      context "new item for new client" do
        setup do
          @item_url = "http://nuevocliente.com/noticia_de_irekia.html"
          assert_difference "ExternalComments::Client.count", 1 do
            assert_difference "ExternalComments::Item.count", 1 do
              get :show, :url => @item_url, :news_id => @irekia_news.id
            end
          end
        end
      
        should "render embed layout" do
          assert_response :success
          assert_template layout: 'embed'
        end
      
        should "not duplicate item once created" do
          assert_no_difference "ExternalComments::Client.count" do
            assert_no_difference "ExternalComments::Item.count" do
              get :show, :url => @item_url, :news_id => @irekia_news.id
            end
          end
        end
      end
    end 

    context "with euskadi.net client" do
      setup do
        @web_lehendakaritza = external_comments_clients(:cliente_lehendakaritza)
        @item_url = "http://www.lehendakaritza.ejgv.euskadi.net/r48-2287/eu/contenidos/noticia/2013_04_16_lhk_unda_santacana/eu_14100/14100.html"        
      end
      
      should "find lehendakaritza client" do
        assert_no_difference "ExternalComments::Client.count" do
          assert_difference "ExternalComments::Item.count", 1 do
            get :show, :url => @item_url, :news_id => @irekia_news.id
          end
        end
        assert_response :success
        
        assert_equal @web_lehendakaritza.id, assigns(:client).id        
      end
    end
    
  end 

  context "with content_local_id" do
    setup do
      @client = external_comments_clients(:euskadinet)
      @content_local_id = "euskadinetNewsID-test"
    end
    
    context "new item" do
      context "for existing client" do
        setup do
          @item_url = "http://#{@client.url}/test.html"
          get :show, :url => @item_url, :content_local_id => @content_local_id
        end
        
        should "render embed layout" do
          assert_response :success
          assert_template layout: 'embed'
        end
        
        context "with non-utf title" do
          setup do
            @item_title = "Título en latin1".encode("gbk", "utf-8").first
            assert !@item_title.is_utf8?
            get :show, :url => @item_url, :content_local_id => @content_local_id, :title => @item_title
          end

          should "render embed layout" do
            assert_response :success
            assert_template layout: 'embed'
          end
        end
      end

      context "new item for new client" do
        setup do
          @item_url = "http://nuevocliente.com/noticia_de_irekia.html"
          assert_difference "ExternalComments::Client.count", 1 do
            assert_difference "ExternalComments::Item.count", 1 do
              get :show, :url => @item_url, :content_local_id => @content_local_id
            end
          end
        end
      
        should "render embed layout" do
          assert_response :success
          assert_template layout: 'embed'
        end
      
        should "not duplicate item once created" do
          assert_no_difference "ExternalComments::Client.count" do
            assert_no_difference "ExternalComments::Item.count" do
              get :show, :url => @item_url, :content_local_id => @content_localid
            end
          end
        end
      end
    end 

    context "with existing client" do
      setup do
        @web_lehendakaritza = external_comments_clients(:cliente_lehendakaritza)
        @item_url = "http://www.lehendakaritza.ejgv.euskadi.net/r48-2287/eu/contenidos/noticia/2013_04_16_lhk_unda_santacana/eu_14100/14100.html"        
        @content_local_id = "euskadinetNewsID-14100"
      end
      
      should "find client for new item" do
        assert_no_difference "ExternalComments::Client.count" do
          assert_difference "ExternalComments::Item.count", 1 do
            get :show, :url => @item_url, :content_local_id => @content_local_id
          end
        end
        assert_response :success
        
        assert_equal @web_lehendakaritza.id, assigns(:client).id        
      end
    end
    
  end 
end
