require 'test_helper'

class SorganizationTest < ActiveSupport::TestCase
  
  test "validates presence of name" do
    sorg=Sorganization.new
    assert_equal false, sorg.save
    assert_equal ['no puede estar vacío'], sorg.errors[:name]
    sorg.name='Irekia'
    assert_difference 'Sorganization.count', +1 do 
      assert_equal true, sorg.save
    end  
  end
  
  # test "validates icon size" do
  #   sorg=Sorganization.new(:icon => File.new(File.join(Rails.root, 'test/data/photos', 'test.jpg')))
  #   assert_equal false, sorg.save
  #   assert_equal 'debe tener un tamaño de 39x37', sorg.errors[:icon]
  # end
  
end  