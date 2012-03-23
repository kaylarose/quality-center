require 'facets'
module QualityCenter
  class Defect < Hash

    # transform the crazy input hash to make it look like a normal one.
    def self.[](input)
      super(input["Fields"]["Field"].map{|x| [x["Name"],x["Value"]]}.reject{|x,y| y.empty? or y == "None"})
    end

  end

  class DefectCollection < Array

    attr_accessor :page_num, :prev, :next, :query

    def initialize(hash)
      # get a field translator
      @total_results = hash["Entities"]["TotalResults"].to_i
    end



  end

end
