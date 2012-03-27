require_relative 'test_helper'

class TestQuery < Test::Unit::TestCase

  include QualityCenter::RemoteInterface

  def assert_query(expected,actual)
    assert_equal(expected,actual.query)
  end

  def test_paginate_default
    assert_query( Query::DEFAULT[:paging], Query.new.paginate )
  end

  def test_paginate_custom
    assert_query( {"page-size"=>9, "start-index"=>14}, Query.new.paginate("page-size"=>9, "start-index"=>14) )
  end

  def test_order_default
    assert_query( {"order-by"=>"{id[DESC]}"}, Query.new.order_by(:id) )
  end
  
  def test_order_custom
    assert_query( {"order-by"=>"{field[ASC]}"}, Query.new.order_by(:field,'direction'=>'ASC') )
  end

  def test_order_check_direction
    assert_raises(ArgumentError) { Query.new.order_by(:field,'direction'=>'BLAH') }
  end

end
