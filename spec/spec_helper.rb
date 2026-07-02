# frozen_string_literal: true

require "bundler/setup"

# pulls in kiba-extend's helpers.rb, which lets you use existing methods for
#   setting up and running transform tests
require "kiba/extend"
kiba_spec_dir = "#{Gem.loaded_specs["kiba-extend"].full_gem_path}/spec"
Dir.glob("#{kiba_spec_dir}/*").sort.select do |path|
  path.match?(/helpers\.rb$/)
end.each do |rbfile|
  require rbfile
end

require_relative "../lib/ke_project"

# A custom rspec matcher to compare expected and given CSVs and provide a usable
#   diff. Use this if you are testing the output of a job that has been
#   finalized, when the input data will not be changing. See the
#   `:locations_clean` test in `./spec/ke_project/jobs/locations_spec.rb` for an
#   example of basic usage.
require "rspec/custom/matchers/match_csv"

# Allows addition of `#reset_config` method for Modules/Classes that extend or
#   include dry-configurable.
require "dry/configurable/test_interface"

# Adds `#reset_config` method to project's base module, allowing you to set
#   configuration settings for individual tests or test groups, then
#   reset to default after
module KeProject
  enable_test_interface
end

RSpec.configure do |config|
  config.extend KeProject

  # This is kiba-extend's spec helpers module which we pulled in above
  config.include Helpers

  # https://lyrasis.github.io/kiba-extend/Kiba/Extend/Utils/TestHelpers.html
  #   Convenience methods for testing different types of job output
  # @note Currently only supports CSV job output
  config.include Kiba::Extend::Utils::TestHelpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
