require 'test_helper'

class AlbumTest < ActiveSupport::TestCase
  test "should have title" do
    a = Album.new()
    assert !a.save
    assert a.errors[:title_es].present?
  end
  
  test "adding photos to an album should update the counter cache" do
    album = albums(:album_one)
    assert_equal 1, album.album_photos_count
    assert_difference 'album.photos.count', +1 do
      album.photos << photos(:photo_two)
    end
    album.reload
    assert_equal 2, album.album_photos_count
  end

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    album = albums(:album_one)
    assert_not_indexed_in_elasticsearch album
    assert album.save
    assert_indexed_in_elasticsearch album
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test('Album')
    album = albums(:album_one)
    assert_indexed_in_elasticsearch album
    assert album.destroy
    assert_deleted_from_elasticsearch album
  end

end
