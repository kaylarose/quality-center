require 'facets/lazy'
require 'andand'
require_relative 'page'

module QualityCenter
  module Defect

    # An array of lazy-loaded Defect::Pages.
    # 
    # Example
    #
    #   include QualityCenter::RemoteInterface
    #   Collection.new( connection: Rest.new(user:'u',password:'p').login ,
    #                   query:      Query.new.filter(id:'<20').paginate )
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

      # The start_index of a given page.
      #
      # page_num - the requested page.
      #
      # Example
      #
      #   coll = Collection.new(query: Query.new.paginate(page_size:6) )
      #   coll.page_start_for(2)
      #   # => 7
      #
      # Returns the index of the requested page.
      def page_start_for(page_num)
        page_size * (page_num - 1) + 1
      end

      # The total number of pages in this collection.
      def page_count
        @page_count ||= ( @total_results / @query.page_size.to_f ).ceil
      end

      # This collection's page size.
      def page_size
        @query.page_size
      end

      # Ensure the deferred computation is evaluated before returning an index.
      #
      # index - the page to retrieve.
      #
      # Example
      #
      #   coll = Collection.new(...)
      #   coll.last
      #   # => #<Lazy::Promise computation=#<Proc: ... >>
      #   coll[2]
      #   # => #<Defect::Page:[[#<Defect::Item:foo>, #<Defect::Item:bar>, ... ]]>
      #
      # Returns the actual content at the requested index
      def [](index)
        demand super(index)
      end

      private

      # Validate initialization arguments and set the class variables.
      #
      # Raises ArgumentError if an invalid connection or query was passed to the constructor.
      def assert_valid_opts(opts)
        raise ArgumentError 'invalid connection' unless opts[:connection].andand.respond_to? :login
        raise ArgumentError 'no query'           unless opts[:query]
        @query = opts[:query]
        @conn  = opts[:connection]
      end

      # Set up the collection by fetching and the first page then creating
      # placeholders for the rest of the pages.
      #
      # Returns self.
      def setup_pages
        response = @conn.scoped_get('/defects', query: query_for_page(1) )
        @total_results = response["Entities"]["TotalResults"].to_i
        @first_page = Page.new(response)

        self << @first_page
        (2..page_count).each do |pg_num|
          self << promise do
            Page.new(@conn.defects(query:query_for_page(pg_num)))
          end
        end
        self
      end

      # A QualityCenter::RemoteInterface::Query object derived from the original
      # input query, modified to retrieve the results for another page.
      #
      # num - The page we want to retrieve.
      #
      # Example
      #
      #   coll = Collection.new(query: Query.new.paginate(page_size:6) )
      #   coll.query_for_page(2).to_hash
      #   # => {"page-size"=>6, "start-index"=>7}
      #
      # Returns a Query for the new page.
      # Raises a RangeError if a page higher than #page_count is requested.
      def query_for_page(num)
        new_query = @query.dup
        case num
        when 1 then new_query.paginate(@query.to_hash.merge 'start-index'=>1 )
        else
          raise RangeError "No such page" if num > page_count
          new_start = page_size * (num - 1) + 1
          new_query.paginate('start-index' => new_start,
                             'page-size'   => @query.page_size)
        end
      end

    end
  end
end
