require 'facets/lazy'
require 'andand'
require_relative 'page'

module QualityCenter
  module Defect

    # An array of lazy-loaded Defect::Pages.
    class Collection < Array

      attr_accessor :query, :total_results, :first_page

      # Create the collection.
      #
      # connection - A usable (i.e. credentialed and logged in) 
      #              QualityCenter::RemoteInterface::Rest instance.
      # query      - A QualityCenter::RemoteInterface::Query object or a
      #              Hash.  Passed to :connection when retrieving results.
      #
      # Example
      #
      #   Collection.new(connection: some_connection, query: some_query)
      #
      # Returns the Collection.
      def initialize(opts={})
        assert_valid_opts(opts)
        setup_pages
      end

      # A QualityCenter::RemoteInterface::Query object derived from the original
      # input query, modified to retrieve the results for another page.
      #
      # num - The page we want to retrieve.
      #
      # Example
      #
      #   query_for_page(5)
      #
      # Returns a Query for the new page.
      # Raises a RangeError if a page higher than #page_count is requested.
      def query_for_page(num)
        raise RangeError "No such page" if num > page_count
        new_query = @query.dup
        new_start = page_size * (num - 1) + 1
        new_query.paginate(start_index:new_start,page_size:@query.page_size)
      end

      # The start_index of a given page.
      def page_start_for(page_num)
        page_size * (page_num - 1) + 1
      end

      def page_count
        @page_count ||= ( @total_results / @query.page_size.to_f ).ceil
      end

      def page_size
        @query.page_size
      end

      private

      # validate initialization arguments
      def assert_valid_opts(opts)
        raise ArgumentError 'invalid connection' unless opts[:connection].andand.respond_to? :login
        raise ArgumentError 'no query'           unless opts[:query]
        @query = opts[:query]
        @conn  = opts[:connection]
      end

      def setup_pages
        response = @conn.defects(@query)
        @total_results = response["Entities"]["TotalResults"].to_i
        @first_page = Page.new(response)

        self << @first_page
        (2..page_count).each do |pg_num|
          self << promise do
            Page.new(@conn.defects(query:query_for_page(pg_num)))
          end
        end
      end


    end
  end
end
