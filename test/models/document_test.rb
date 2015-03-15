require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  
  test "title_es should be present" do
    doc = Document.new(:title_es => "The title", :organization => organizations(:lehendakaritza))
    assert doc.valid?
    
    doc.title_es = nil
    assert !doc.valid?
  end  

  test "document areas area ordered by position" do
    area1 = areas(:a_lehendakaritza)
    area2 = areas(:a_interior)
    doc = Document.create(:title_es => "The title", :organization => organizations(:lehendakaritza), :tag_list => area1.tag_list+area2.tag_list)

    assert_equal [area1, area2], doc.areas
  end    

  test "avatar is the document area avatar" do
    I18n.locale = :eu
    area = areas(:a_lehendakaritza)
    doc = Document.create(:title_es => "The title", :organization => organizations(:lehendakaritza), :tag_list => area.tag_list)
    assert_equal area, doc.area
  end    
  
end
