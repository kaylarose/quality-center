# -*- encoding: utf-8 -*-
require File.expand_path('../lib/quality_center/version', __FILE__)

Gem::Specification.new do |s|
  s.name                  = "quality_center"
  s.authors               = ["Carl Brasic"]
  s.email                 = ["Carl.Brasic@pearson.com"]
  s.summary               = "Ruby interface to the HP ALM API"
  s.description           = "Export info from HP's Application Lifecycle Management tool (a.k.a Quality Center) into simple ruby structures.  Large datasets are auto-paginated and lazy-loaded."
  s.homepage              = "http://github.com/Pearson-AI/quality-center"
  s.required_ruby_version = ">= 1.9.2"

  s.add_dependency 'nokogiri'
  s.add_dependency 'httparty'
  s.add_dependency 'activesupport'
  s.add_dependency 'facets'
  s.add_dependency 'andand'

  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'simplecov'

  s.files                 = `git ls-files`.split("\n") rescue ''
  s.test_files            = `git ls-files -- test/*`.split("\n")
  s.require_paths         = ["lib"]
  s.version               = QualityCenter::VERSION
end
