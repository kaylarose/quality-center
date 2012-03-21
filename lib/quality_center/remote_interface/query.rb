require 'active_support/core_ext/hash'

module QualityCenter
  module RemoteInterface

    # The query segment of a QC REST call, including parameters to filter and sort results.
    # See the docs at qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/webframe.html
    # Example:
    # q = Query.new.filter(id:'<9',product:'SORM*').paginate(limit:20)
    class Query

      attr_accessor :query

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
      # {subject[predicate]}
      def wrap(subject,predicate)
        bracket( clause(subject,predicate) )
      end
      
      # Produce a bracketed expression for use in a QC query:
      # {input}
      def bracket(s)
        "{#{s}}"
      end

      # The basic syntax of a QC parameter:
      # subject[predicate]
      def clause(subject,predicate)
        "#{subject}[#{predicate}]"
      end


      # Add a page limit.  QC defaults to 100, we default to 10.
      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/Data_Paging.html
      def paginate(opts = {})
        opts.reverse_merge! DEFAULT[:paging]
        add( page_size:   opts[:limit],
             start_index: opts[:offset] + 1 )
        self
      end

      # Order by a field, descending by default.
      # TODO support multiple order clauses
      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/order-by.html
      def order_by(opts = {})
        opts = assert_legal_order(opts)
        add order_by: wrap( opts[:field], opts[:direction] )
        self
      end

      # Limit returned entries by their values.
      # input: {field1: val1, ... fieldn: valn}
      # http://qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/Filtering.html
      def filter(opts = {})
        assert_legal_filter(opts)
        add(:query => bracket(opts.
                                map{ |field,value| clause(field,value) }.
                                join(';')
                             )
           )
        self
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

