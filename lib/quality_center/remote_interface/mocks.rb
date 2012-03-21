module QualityCenter
  module RemoteInterface
    module Mocks
      class Rest

        FIXTURES = '/home/brasca/git/qc_rest/fixtures/'

        def users
          fixture(:users)
        end

        def defect_fields
          fixture(:defect_fields)
        end

        def defects
          fixture(:defects)
        end

        private
        def fixture(name)
          File.read(FIXTURES+name.to_s+'.xml')
        end

      end
    end
  end
end
