require 'facets/lazy'
require 'active_support/core_ext/hash'

module QualityCenter
  class Defect < Hash

    # transform the crazy input hash to make it look like a normal one.
    def self.[](input)
      super(input["Fields"]["Field"].map{|x| [x["Name"],x["Value"]]}.reject{|x,y| y.empty? or y == "None"})
    end

    def inspect
      "#<Defect:#{self['name']}>"
    end

  end

  class DefectPage < Array
    def initialize(hash)
      super(hash["Entities"]["Entity"].map{ |d| Defect[d] })
    end
  end

  class DefectCollection < Array

    attr_accessor :query, :total_results,:first_page

    def initialize(opts={})
      @conn = opts[:connection]
      raise ArgumentError 'invalid connection' unless @conn.respond_to? :login
      raise ArgumentError 'no query'           unless (@query=opts[:query])
      response = @conn.defects(opts.slice :query)
      @total_results = response["Entities"]["TotalResults"].to_i

      @first_page = DefectPage.new(response)
    end

    def setup_pages
      self << @first_page
      (2..page_count).each do |pg_num|
        self << promise do
          DefectPage.new(@conn.defects(query:query_for_page(pg_num)))
        end
      end
    end

    def query_for_page(num)
      new_query = @query.deep_clone
      raise "No such page" if num > page_count
      new_start = @query.page_size * (num - 1) + 1
      new_query.paginate(start_index:new_start,page_size:@query.page_size)
    end

    def page_count
      @page_count ||= ( @total_results / @query.page_size.to_f ).ceil
    end

    def page_size
      @query.page_size
    end


  end

end



class Object
  def deep_clone
    Marshal::load(Marshal.dump(self))
  end
end
