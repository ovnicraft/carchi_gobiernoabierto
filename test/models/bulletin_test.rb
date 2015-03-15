require 'test_helper'

class BulletinTest < ActiveSupport::TestCase
  context "without featured news for bulletin" do
    should "create bulletin with no featured news" do
      bulletin = Bulletin.new
      assert bulletin.save
      assert bulletin.featured_news_ids.length == 0
    end
  end

  context "with featured news for bulletin" do
    setup do
      documents(:one_news).update_attributes(:featured_bulletin => true)
      documents(:featured_news).update_attributes(:featured_bulletin => true)
    end

    should "not include them in bulletin" do
      bulletin = Bulletin.new
      assert bulletin.save
      # assert_equal [documents(:one_news).id, documents(:featured_news).id].sort,  bulletin.featured_news_ids.sort
      # Now they should be explicitly selected
      assert bulletin.featured_news_ids.length == 0
    end

    should "include them if explicitly selected" do
      bulletin = Bulletin.new(:featured_news_ids => [documents(:one_news).id, documents(:featured_news).id])
      assert bulletin.save
      assert_equal [documents(:one_news).id, documents(:featured_news).id].sort,  bulletin.featured_news_ids.sort
    end
  end

 if Settings.optional_modules.debates
  context "without featured debate for bulletin" do
    should "create bulletin with no featured debate" do
      bulletin = Bulletin.new
      assert bulletin.save
      assert bulletin.featured_debate_ids.length == 0
    end
  end

  context "with featured debates for bulletin" do
    setup do
      debates(:debate_completo).update_attributes(:featured_bulletin => true)
    end

    should "not include it in bulletin" do
      bulletin = Bulletin.new
      assert bulletin.save
      # assert_equal [debates(:debate_completo).id].sort,  bulletin.featured_debate_ids.sort
      # Now they should be explicitly selected
      assert bulletin.featured_debate_ids.length == 0
    end

    should "include them if explicitly selected" do
      bulletin = Bulletin.new(:featured_debate_ids => [debates(:debate_completo).id])
      assert bulletin.save
      assert_equal [debates(:debate_completo).id].sort,  bulletin.featured_debate_ids.sort
    end
  end
 end
end
