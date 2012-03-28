require 'quality_center/defect/item'

module QualityCenter
  module Defect

    # An array that knows how to create Defect::Items.
    class Page < Array

      # create the Defect::Items
      def initialize(hash)
        create_defects = Proc.new{ |d| Item[d] }

        # call the normal Array constructor on our list of Defects.
        super( root_of(hash).map(&create_defects) )
      end

      # Where the defects actually live inside the expected input.
      def root_of(input_hash)
        input_hash["Entities"]["Entity"] rescue []
      end

    end
  end
end
