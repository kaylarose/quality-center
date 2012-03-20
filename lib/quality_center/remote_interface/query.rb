require 'active_support/core_ext/hash'

module QualityCenter
  module RemoteInterface
    class Query

      DEFAULT = {
        paging: { limit: 10,   offset: 0 },
        order:  { field: 'id', direction: 'DESC' }
      }

      DIRECTIONS = %w[ASC DESC]

      # start a blank query accumulator
      def initialize
        @query = {}
      end

      # Add a parameter to the query accumulator.
      def add(new_attribute = {})
        new_attribute.stringify_keys!
        new_attribute.dashify_keys!
        @query.merge! new_attribute
      end

      # Produce a string of the form frequently used in QC queries:
      #  {subject[predicate]}
      def wrap(subject,predicate)
        "{#{subject}[#{predicate}]}"
      end


      # Add a page limit.  QC defaults to 100, we default to 10.
      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/Data_Paging.html
      def paginate(opts = {})
        opts.reverse_merge! DEFAULT[:paging]
        add( page_size:   opts[:limit],
             start_index: opts[:offset] + 1 )
      end

      # Order by a field, descending by default.
      # TODO support multiple order clauses
      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/order-by.html
      def order_by(opts = {})
        opts = assert_legal_order(opts)
        add order_by: wrap( opts[:field], opts[:direction] )
      end

      # Limit returned entries by their values.
      # input: {field1: val1, ... fieldn: valn}
      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/Filtering.html
      def filter(opts = {})
        assert_legal_filter(opts)
        add(:query => opts.
                        map{ |field,value| wrap(field,value) }.
                        join(';') 
           )
      end

      # Ensure the order opts make sense
      def assert_legal_order(opts)
        opts.symbolize_keys!
        opts.reverse_merge! DEFAULT[:order]
        opts[:direction].upcase!
        raise ArgumentError.new(':field required')   unless opts.include? :field
        raise ArgumentError.new("Illegal Direction") unless DIRECTIONS.include? opts[:direction]
        opts
      end

      # Make sure we were passed a nonempty hash with no blanks.
      def assert_legal_filter(opts)
        raise ArgumentError.new('empty hash')            if opts.empty?
        raise ArgumentError.new('missing filter clause') if opts.values.any?(&:empty?)
      end

    end
  end
end

#utility so we can use syms with underscores for hashes but still output the dashes QC expects
class Hash

  def dashify_keys!
    self.replace Hash[ self.keys.map{|x| x.gsub('_','-')}.zip(self.values) ]
  end

end

# notes:
#"/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={detected-by[egolal]}&order-by={last-modified[DESC]}"
#"/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=1&query={detected-by[NOT(egolal)]}"
#"/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={id[1 or 2 or 3 or 4 or 5]}&order-by={last-modified[DESC]}"
#"/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={id[<10]}&order-by={last-modified[DESC]}"
#"/domains/TEST/projects/AssessmentQualityGroup/defects?page-size=5&query={name[*SORM*]}"

