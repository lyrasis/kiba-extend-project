# frozen_string_literal: true

module KeProject
  module TargetSystem
    module Locations
      extend self

      # This shows the typical pattern of three methods:
      #   - `base` method to call the job
      #   - `base_config` to set up the files
      #   - `base_logic` to define the transforms
      def for_import
        Kiba::Extend::Jobs::Job.new(files: for_import_config, transformer: for_import_logic)
      end

      # Every job needs a source and destination, each of which is a key registered in your
      #   registry_data.rb
      def for_import_config
        {
          source: :auth__loc__clean,
          destination: :locations,
          lookup: :auth__loc__clean_rev
        }
      end

      def for_import_logic
        Kiba.job_segment do
          transform Merge::MultiRowLookup,
            keycolumn: :location_id,
            lookup: auth__loc__clean_rev,
            fieldmap: {
              reversed_location: :loc_name_reversed
            },
            constantmap: {
              update_date: Date.today.to_s}
          transform Delete::Fields, fields: %i[location_id]
        end
      end

      def for_endpoint
        Kiba::Extend::Jobs::Job.new(files: for_endpoint_config, transformer: for_endpoint_logic)
      end

      # Every job needs a source and destination, each of which is a key registered in your
      #   registry_data.rb
      def for_endpoint_config
        {
          source: :locations,
          destination: :auth__loc__json
        }
      end

      def for_endpoint_logic
        Kiba.job_segment do
          transform Merge::ConstantValue, target: :data_source, value: 'source system'

          # example of a one-off, non-reusable, job-specific transform
          transform do |row|
            val = row.fetch(:reversed_location, nil)
            next row if val.blank?

            row[:reversed_location] = val.downcase
            row
          end

        end
      end
    end
  end
end
