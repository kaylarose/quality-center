require 'yaml'
require_relative '../constants'
module QualityCenter
  module RemoteInterface
    module Mocks
      class Rest

        def users(opts={})
          fixture(:users,opts)
        end

        def defect_fields(opts={})
          fixture(:defect_fields,opts)
        end

        def defects(opts={})
          fixture(:defects,opts)
        end

        # stubs for unimplemented mocks.
        def auth_get;          raise NotImplementedError; end
        def scoped_get;        raise NotImplementedError; end
        def login;             true; end
        def is_authenticated?; true; end

        private

        def fixture(name,opts={})
          if opts[:raw]
            raw_xml(name)
          else
            YAML.load( fixture_file(name) )
          end
        end

        def fixture_file(name)
          File.read "#{FIXTURES+name.to_s}.yml"
        end

        def raw_xml(name)
          File.read "#{FIXTURES+name.to_s}.xml"
        end

      end
    end
  end
end
