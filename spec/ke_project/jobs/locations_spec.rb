# frozen_string_literal: true

require "spec_helper"

# Standard Ruby practice would have us putting tests for :locations_clean
#   in a separate file at ./spec/ke_project/jobs/locations/clean_spec.rb
#
# I've found that putting tests for all jobs in a given namespace has some
#   practical benefits that outweigh the folly of transgressing
#   conventions (in my case, this is mainly that my text editor cannot
#   automatically jump me back and forth between the job definition module
#   file and the test file). These include:
#
# - You can write tests for the same field in the same row in each job
#   sequentially, and visually scroll through one file to see the
#   expectations
# - Setup of test contexts is more straightforward.
# - Less new-file-creation friction, as testing is easy to neglect in a
#   migration project, and anything to make it easier is better
#
# Here we are testing the output of some typical jobs in two ways...
RSpec.describe KeProject::Jobs::Locations do
  # For this job, we are spot checking to verify the transforms we
  #   wrote work as expected
  # @note The best to ensure transforms work as expected
  #   is in tests of the transform classes, whether those are in
  #   kiba-extend or your project. You can generally assume that transforms
  #   that come with kiba-extend are well-tested and you do not need to
  #   test their basic functionality.
  #
  # I'm doing some simple tests of these transforms here because this
  #   project isn't complex enough to demonstrate where job tests really
  #   shine: ensuring complexities of run order, side effects
  #   of config changes, etc. do not have unexpected impact on data as it
  #   flows through your project. These will just show some patterns I
  #   commonly find useful in this kind of testing
  describe ":locations__clean_rev" do
    # This setup depends on the inclusion of
    #   `Kiba::Extend::Utils::TestHelpers` in your RSpec config in
    #   `./spec/spec_helper.rb
    let(:data) { csv_job_output(:locations__clean_rev) }

    it "renames :loc_id to :location_id" do
      expect(data.headers).to include(:location_id)
      expect(data.headers).not_to include(:loc_id)
    end

    it "deletes updated_date" do
      expect(data.headers).not_to include(:updated_date)
    end

    it "reverses loc_names" do
      row = data.find { |row| row[:loc_name] == "U-StorIt" }
      expect(row[:loc_name_reversed]).to eq("tIrotS-U")
    end
  end

  # Here we will compare the entire output file to the expected output file.
  # The benefit of this approach are that it finds any small differences
  #   anywhere in your file. The downsides are numerous, though:
  #
  # - You need to save a copy of the expected file output somewhere it won't
  #   be overwritten, usually in a `./spec/support/fixtures` directory
  # - Any change you make to the job, or its dependencies, are likely to break
  #   the test. In this case, it's expected that the job output will no
  #   longer match the output.
  # - If you get fresh data, the tests will likely fail, since the project input
  #   data will have changed.
  #
  # Generally I use this approach with fake, static files I create when
  #   implementing new iterative cleanup processes. That's more complicated than
  #   what I will show you here.
  #
  # This test type depends on the `require "rspec/custom/matchers/match_csv"`
  #   line in your project's `spec_helper.rb` file.
  describe ":locations__clean" do
    before { Kiba::Extend::Command::Run.job(:locations__clean) }
    it "produces expected output" do
      expected_path = File.join(Bundler.root, "spec", "support", "fixtures",
        "loc_clean.csv")
      result_path = KeProject.registry
        .resolve(:locations__clean)
        .path

      expect(result_path).to match_csv(expected_path)
    end
  end
end
