require 'test_helper'

class PhotoTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  test "should not have empty title" do
    photo = Photo.new(:file_path => "photos/fixture3.png")
    assert !photo.save
    [:title_es, :title_eu, :title_en].each do |field|
      assert_equal true, photo.errors[field.to_sym].include?("no puede estar vacío")
    end
  end

  test "should not have empty file_path" do
    photo = Photo.new(:title_es => "Title", :title_eu => "Titulo", :title_en => "Titulo")
    assert !photo.save
    assert_equal ["no puede estar vacío"], photo.errors[:file_path]
  end

  test "should not duplicate paths" do
    photo = Photo.new(:title_es => "Title", :title_eu => "Titulo", :title_en => "Titulo", :file_path => "photos/fixture.png")
    assert !photo.save
    assert_equal ["ya está cogido"], photo.errors[:file_path]
  end

  test "should save tags" do
    photo = photos(:photo_one)

    assert_difference 'photo.tags.count', +1 do
      photo.tag_list.add tags(:irekia_actos).name_es
      photo.save
    end
  end

  test "cannot create photo with path containing spaces" do
    photo = Photo.new(:dir_path => "photos/This has spaces")
    assert !photo.valid?, "expected photo to be invalid"
    assert photo.errors[:dir_path], "expected photo to have incorrect directory"
  end

  test "orphane photo is not published" do
    photo = photos(:orphane_photo)
    assert !photo.published?
  end

end
