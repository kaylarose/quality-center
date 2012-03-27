require 'active_support/inflections'
require_relative '../constants'

module QualityCenter
  module RemoteInterface

    # Some methods for parsing and handling arbitrary entities.
    module GenericEntityParser

      # Catchall for entity fetches not specifically coded for.
      # Results may be automatically page-limited, so using this requires that
      # you implement your own paging (see QualityCenter::Defect for an example).
      #
      # Example
      # 
      #   conn.releases(query:query)
      #
      # Returns a hash with these keys:
      #   count    - the unpaginated result set.
      #   entities - the entity list if it exists.
      #   query    - the original query used to fetch the list
      #   type     - the type of entity returned.
      #   
      def generic_entity_fetch(entity_name,opts={})
        res = scoped_get("/#{entity_name}",opts)

        entities = res['Entities']['Entity'].map do |x|
          response_to_hash(x,value_field:"Value") 
        end rescue []

        { count:    res["Entities"]["TotalResults"].to_i,
          query:    opts[:query],
          type:     entity_name.to_s.singularize,
          entities: entities }
      end

      # A map from machine-readable field names to human-readable labels.
      #
      # entity - the type of entity whose field map is to be retrieved.
      #
      # Returns a Hash like {'user-06'=>'Environment", 'user-01'=> 'External ID'}
      def entity_fields(opts={})
        opts.reverse_merge! entity:'defect'
        res = scoped_get("/customization/entities/#{opts[:entity].to_s.singularize}/fields",opts)
        response_to_hash(res)
      end


      # Turns a complicated HTTParty response into a simpler hash.
      def response_to_hash(response,opts={})
        opts.reverse_merge!(entity_name: 'Field',
                            key_field:   'Name',
                            value_field: 'Label',
                            key_process: :to_s,
                            val_process: :to_s)

        root = response[opts[:entity_name].pluralize][opts[:entity_name]]

        # The definition of "emptiness" for a field.
        # viz. an empty string or a string that equals "None"
        is_empty = Proc.new{ |x,y| y.empty? or y == "None" }

        Hash[ root.map do |entity| 
                [
                  entity[opts[:key_field]].  send(opts[:key_process]),
                  entity[opts[:value_field]].send(opts[:val_process])
                ]
              end.reject(&is_empty) 
            ]
      end

    end
  end
end
