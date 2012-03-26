require_relative 'test_helper'

class TestQuery < Test::Unit::TestCase

  include QualityCenter::RemoteInterface

  def test_paginate_default
    assert_equal( Query::DEFAULT[:paging], Query.new.paginate.query)
  end

  def test_paginate_custom
    assert_equal( {"page-size"=>9, "start-index"=>14}, Query.new.paginate("page-size"=>9, "start-index"=>14).query )
  end

  def test_order_default
    assert_equal( {"order-by"=>"{id[DESC]}"}, Query.new.order_by(:id).query )
  end
  
  def test_order_custom
    assert_equal( {"order-by"=>"{field[ASC]}"}, Query.new.order_by(:field,'direction'=>'ASC').query )
  end

  def test_order_check_direction
    assert_raises(ArgumentError) { Query.new.order_by(:field,'direction'=>'BLAH') }
  end

end
