require 'test_helper'

class CategoryTest < ActiveSupport::TestCase

  test "roots" do
    roots = Category.roots()
    assert !roots.empty?
    assert_nil roots.detect {|cat| !cat.parent_id.nil?}
  end
  
  test "web tv tags" do
    cat = categories(:cat_webtv_interior)
    assert_equal [tags(:interior_tag).name_es], cat.tag_list
    
    assert_not_nil cat.videos
  end
    
  test "videos" do
    cat = categories(:cat_webtv_lehendakaritza)
    assert_equal [videos(:every_language), videos(:video_lehendakaritza)], cat.videos.order('published_at DESC')
    
    assert_equal [videos(:video_dept_interior)], categories(:cat_webtv_interior).videos
    assert_equal [videos(:every_language)], categories(:cat_de_webtv).videos
  end
  
  test "albums should not contain empty albums" do
    cat = categories(:cat_de_fototeca_interior)
    
    assert !cat.albums.include?(albums(:album_dept_interior_empty))
  end
end
