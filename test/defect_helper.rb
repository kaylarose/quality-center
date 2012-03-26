require_relative 'rest_helper'

module DefectHelper

  include RestHelper

  def with_a_collection
    while_logged_in do
      @query=QualityCenter::RemoteInterface::Query.new.filter(id:'<20').paginate(page_size:7).order_by(:id)
      @coll=QualityCenter::Defect::Collection.new(connection:@conn,query:@query)
      yield
    end
  end

  def with_a_page
    with_a_collection{ @page = @coll.first; yield }
  end

  def with_an_item
    with_a_page{ @item = @page.first; yield }
  end

end

