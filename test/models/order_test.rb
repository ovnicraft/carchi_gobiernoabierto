require 'test_helper'

class OrderTest < ActiveSupport::TestCase

  ['titulo', 'texto', 'rango', 'seccion'].each do |att|
    test "validates presence and translation of #{att}" do
      order = Order.new()
      assert_equal false, order.valid?
      assert_equal ['no puede estar vacío'], order.errors[att.to_sym]
    end
  end

  ['fecha_bol', 'no_bol', 'no_orden'].each do |att|
    test "validates presence of #{att}" do
      order = Order.new()
      assert_equal false, order.valid?
      assert_equal ['no puede estar vacío'], order.errors[att.to_sym]
    end
  end

  test "validates uniqueness of no_orden" do
    order = Order.new(:no_orden => '20001001')
    assert_equal false, order.valid?
    assert_equal ['ya está cogido'], order.errors[:no_orden]
  end

  test "create valid order" do
    order = Order.new(:titulo_es => 'Orden2', :texto_es => 'Texto Orden2', :seccion_es => 'Seccion2', :rango_es => 'Rango1', :fecha_bol => Date.today, :no_orden => '20001002', :no_bol => '1000')
    assert_equal true, order.save
  end

  test "should index to elasticsearch related after save" do
    prepare_bopv_elasticsearch_test
    order = orders(:order_one)
    assert_deleted_from_elasticsearch order, Elasticsearch::Base::BOPV_URI
    assert order.save
    assert_indexed_in_elasticsearch order, Elasticsearch::Base::BOPV_URI
  end

  test "should delete from elasticsearch related after destroy" do
    prepare_bopv_elasticsearch_test
    order = orders(:order_one)
    assert_deleted_from_elasticsearch order, Elasticsearch::Base::BOPV_URI
    assert order.save
    assert_indexed_in_elasticsearch order, Elasticsearch::Base::BOPV_URI
    assert order.destroy
    assert_deleted_from_elasticsearch order, Elasticsearch::Base::BOPV_URI
  end


end
