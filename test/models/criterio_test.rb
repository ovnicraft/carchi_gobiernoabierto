require 'test_helper'

class CriterioTest < ActiveSupport::TestCase
  
  test "validates presence of title and ip" do
    criterio=Criterio.new
    assert_equal false, criterio.save
    criterio.title='keyword: cultura'
    assert_equal false, criterio.save
    criterio.ip='127.0.0.1'
    assert_equal true, criterio.save
  end
  
  test "criterio acts as tree" do
    criterio_parent=criterios(:criterio_one)
    criterio=criterios(:criterio_two)
    assert_equal criterio_parent, criterio.parent
  end
  
  test "destroy criterio" do
    criterio=criterios(:criterio_two)
    assert_difference 'Criterio.count', -1 do 
      criterio.destroy
    end
  end
  
  test "get keywords" do
    criterio = Criterio.new(title: 'keyword: ONE AND tags: TAGS AND keyword: al TWO')
    assert_equal "ONE TWO", criterio.get_keywords
  end

  test "last part" do
    criterio = Criterio.new(title: 'keyword: ONE AND tags: TAGS AND keyword: TWO')
    assert_equal "keyword: TWO", criterio.last_part
  end
end