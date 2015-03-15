require 'test_helper'

class ExternalComments::ItemTest < ActiveSupport::TestCase
  context "item with comments" do
    setup do
      @item_es = external_comments_items(:euskadinet_item_commentable_irekia_news)
      @item_eu = external_comments_items(:euskadinet_item_commentable_irekia_news_eu)
      @irekia_news = documents(:commentable_news)

      assert_equal @irekia_news.id, @item_es.irekia_news_id
      assert_equal @irekia_news.id, @item_eu.irekia_news_id

      @external_comments_es = @item_es.comments
      @external_comments_eu = @item_eu.comments
      @irekia_comments = @irekia_news.comments
      @all_comments = @external_comments_es + @external_comments_eu + @irekia_comments
    end

    should "get only external item comments" do
      @external_comments_es.each do |comment|
        assert_nil @irekia_comments.detect {|c| c.eql?(comment)}
      end
      @external_comments_eu.each do |comment|
        assert_nil @irekia_comments.detect {|c| c.eql?(comment)}
      end
    end

    should "get all comments" do
      all_comments = @item_es.all_comments.map {|c| c.id}

      assert_equal @all_comments.length, all_comments.length

      assert_equal all_comments.sort, @all_comments.map {|c| c.id}.sort
    end    
  end

  context "programa comments" do
    setup do
      @item_es = external_comments_items(:programa_item_es)
      @item_eu = external_comments_items(:programa_item_eu)
    end

    should "get es and eu comments for es client" do
      assert_equal 1, @item_es.comments.size
      assert_equal 1, @item_es.all_comments.size
      assert_equal 1, @item_eu.comments.size
      assert_equal 1, @item_eu.all_comments.size
    end

  end

  context "euskadinet comments" do
    setup do
      @item1 = external_comments_items(:euskadinet_item1)
      @item2 = external_comments_items(:lehendakaritza_item_for_euskadinet_item1)
      @all_comments = @item1.comments.size + @item2.comments.size

      assert_equal @item1.content_local_id, @item2.content_local_id
    end

    should "get all coments for each client" do
      assert_equal @all_comments, @item1.all_comments.size 
      assert_equal @all_comments, @item2.all_comments.size 
    end

  end

  context "countable" do
    setup do
      @a_interior_external_comments_item = FactoryGirl.create(:external_comments_item, :client => FactoryGirl.create(:external_comments_client, :organization_id => organizations(:interior).id))
      @stats_counter = @a_interior_external_comments_item.stats_counter
    end

    should "have correct area and department in stats_counter" do
      assert_equal nil,  @stats_counter.area_id
      assert_equal organizations(:interior).id, @stats_counter.organization_id
      assert_equal organizations(:interior).id, @stats_counter.department_id
    end
  end



end
