require "vcr"

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir     = "features/cassettes"
  c.default_cassette_options = { :record => :once }
end

VCR.cucumber_tags do |t|
  t.tags  "@basic_auth",
          "@batch_request",
          "@complex_types",
          "@error_handling",
          "@query_builder",
          "@service",
          "@service_manage",
          "@service_methods",
          "@ssl",
          "@type_conversion"
end