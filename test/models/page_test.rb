require "test_helper"

class PageTest < ActiveSupport::TestCase
  
  test "class_name is Document" do
    page = Page.first
    assert_equal "Document", page.class_name
  end

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    page = documents(:page_in_menu)
    assert_deleted_from_elasticsearch page
    assert page.save
    assert_indexed_in_elasticsearch page
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test
    page = documents(:page_in_menu)
    assert_deleted_from_elasticsearch page
    assert page.save
    assert_indexed_in_elasticsearch page
    assert page.destroy
    assert_deleted_from_elasticsearch page
    clear_multimedia_dir(page)
  end

 if Settings.optional_modules.debates
  context "with debate" do

    should "have debate" do
      page = documents(:debate_page)
      debate = debates(:debate_completo)

      assert_equal debate, page.debate
    end

    should "assign debate" do
      page = documents(:published_page)
      debate = debates(:debate_nuevo)
      
      assert_nil page.debate
      
      page.debate_id = debate.id
      page.multimedia_dir = "aportaciones_#{debate.multimedia_dir}"
      assert page.save
      
      assert_equal debate, page.debate
    end    
    
    should "nullify page when deleted" do
      page = documents(:debate_page)
      debate = debates(:debate_completo)
      
      assert_equal debate, page.debate
      
      assert page.destroy
      
      debate.reload
      
      assert_nil debate.page_id
    end
  end
 end
end
