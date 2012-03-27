require_relative 'defect_helper'

class TestDefects < Test::Unit::TestCase

  include DefectHelper

  # Create a Collection.
  # Our fixtures say this should exist and be nonempty.
  def test_create_collection
    with_a_collection do
      assert_instance_of QualityCenter::Defect::Collection, @coll
      refute @coll.empty?
    end
  end

  # Check that a Collection is made of Pages and is populated correctly.
  def test_create_page
    with_a_page do
      assert_instance_of QualityCenter::Defect::Page, @page
      refute @page.empty?
    end
  end

  # Check that Pages are made of Items.
  def test_create_item
    with_an_item do
      assert_instance_of QualityCenter::Defect::Item, @item
      refute @page.empty?
    end
  end

  # Check that the inspect method works.
  def test_inspect_item
    with_an_item do
      assert_match /<Defect::Item/, @item.inspect
    end
  end

  # Check that the page_start_for method works.
  def test_page_start_for
    with_a_collection do
      assert_equal(1,  @coll.page_start_for(1))
      assert_equal(11, @coll.page_start_for(2))
    end
  end

  # Check that the index access override method works.
  def test_index_access
    with_a_collection do
      assert_equal(@coll.first, @coll[0])
    end
  end

  # Verify that pages are lazy-loaded on demand.
  def test_lazy_fetch
    with_a_collection do
      
      # using the __class__ instance variable this looks like a Promise.
      assert_equal Lazy::Promise, @coll.last.__class__

      # once we check the class using #class, the result is fetched and now it's a Page.
      assert_equal QualityCenter::Defect::Page, @coll.last.class
    end
  end

  # Make sure the collection can flatten into a list of Defect::Items
  def test_flatten
    with_a_collection do
      assert_equal 10, @coll.flatten!.size
      assert_instance_of QualityCenter::Defect::Item, @coll.last
    end
  end

end
