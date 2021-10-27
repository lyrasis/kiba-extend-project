# frozen_string_literal: true

module KeProject
  module SourceSystem
    module Locations
      extend self

      # This shows a variation on the typical pattern of three methods:
      #   - `base` method to call the job
      #   - `base_config` to set up the files
      #   - `base_logic` to define the transforms
      #
      # It allows most of the logic in `clean_logic` to be used, with some variation
      #   based on the parameter passed in
      def clean
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__locations,
            destination: :auth__loc__clean
          },
          transformer: clean_logic(direction: :direct)
          )
      end

      def clean_reverse
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :orig__locations,
            destination: :auth__loc__clean_rev
          },
          transformer: clean_logic(direction: :reversed)
        )
      end

      # when called with `direction: :reversed`, uses a project-specific transform
      def clean_logic(direction:)
        Kiba.job_segment do
          transform Rename::Field, from: :loc_id, to: :location_id
          transform Delete::Fields, fields: %i[updated_date]
          transform KeProject::Transforms::Locations::LocNameReverser, replace: false if direction == :reversed
        end
      end

    end
  end
end
