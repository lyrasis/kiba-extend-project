# frozen_string_literal: true

require "bundler/setup"

# pulls in kiba-extend's helpers.rb, which lets you use existing methods for
#   setting up and running transform tests
require "kiba/extend"
kiba_spec_dir = "#{Gem.loaded_specs["kiba-extend"].full_gem_path}/spec"
Dir.glob("#{kiba_spec_dir}/*").sort.select { |path|
  path.match?(/helpers\.rb$/)
}.each do |rbfile|
  require rbfile
end

require_relative "../lib/ke_project"

# A custom rspec matcher to compare expected and given CSVs and provide a usable
#   diff. Use this if you are testing the output of a job. See example of use in
#   https://github.com/lyrasis/kiba-tms/blob/main/spec/kiba/tms/mixins/reportable_for_table_spec.rb
require "rspec/custom/matchers/match_csv"

RSpec.configure do |config|
  config.extend KeProject
  config.include Helpers
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
