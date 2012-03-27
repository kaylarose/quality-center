require_relative 'test_helper'

include QualityCenter::RemoteInterface

def with_queries
  @small_query = Query.new.paginate(page_size:2)
  @single_page_query = Query.new.paginate(page_size:1)
  yield
end

