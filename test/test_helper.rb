require 'test/unit'
require 'webmock'
require 'vcr'
require_relative '../lib/quality_center.rb'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
end

