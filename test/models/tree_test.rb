require 'test_helper'

class TreeTest < ActiveSupport::TestCase
  
  test "validate uniqueness of label" do
    tree = Tree.new(:name_es => 'Videos1', :name_eu => 'Videos1', :name_en => 'Videos1', :label => 'videos')
    assert_equal false, tree.save
    assert_equal ['ya está cogido'], tree.errors[:label]
  end
  
  test "class finder methods" do
    menu = trees(:web_tv)
    assert_equal menu, Tree.find_videos_tree
  end
  
end
