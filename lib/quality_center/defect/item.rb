module QualityCenter
  module Defect

    # An individual defect.
    class Item < Hash

      # Override Hash constructor to transform the crazy structure produced by
      # HTTParty from the REST output and make it look like a normal hash.
      #
      # Returns the Item.
      def self.[](input)

        # The definition of "emptiness" for a field.
        # viz. an empty string or a string that equals "None"
        is_empty = Proc.new{ |x,y| y.empty? or y == "None" }

        # What fields are going to be the key and the value for the output hash?
        key_pair = Proc.new{ |field| [ 
                                       field["Name"], field["Value"] 
                                     ] 
                           }

        # Call the 1.9-style array-of-KVs Hash constructor on our list of pairs.
        super( input["Fields"]["Field"].  
               map(&key_pair).
               reject(&is_empty) 
             )
      end

      # Cut down on noise when we're inspecting.
      #
      # Returns a compact string representing the Item.
      def inspect
        "#<Defect::Item:#{self['name']}>"
      end

    end
  end
end
