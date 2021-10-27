# frozen_string_literal: true

module KeProject
  module TargetSystem
    module Locations
      extend self

      # This shows the typical pattern of three methods:
      #   - `base` method to call the job
      #   - `base_config` to set up the files
      #   - `base_logic` to define the transforms

      # This is the method recorded in the `creator` key of the registry entry `:locations`.
      # The first part of the `creator` value is the module hierarchy
      def for_import
        Kiba::Extend::Jobs::Job.new(files: for_import_config, transformer: for_import_logic)
      end

      # Every job needs a source and destination, each of which is a key registered in your
      #   registry_data.rb
      #
      # This config method is called by the `for_import` method above.
      # The `for_import` method is the creator value for the `:locations` registry entry.
      # The destination is defined by the `:locations` registry entry.
      #
      # This pattern is almost always present in typical jobs.
      #
      # Lookups are optional, and you may have more than one lookup for a given job. If so,
      #   you define them like:
      #     lookup: %i[first_lookup second_lookup]
      #
      # Note that any registry entry that will be used as a lookup needs to have a `lookup_on` key
      #   defined in the registry entry. This is the field/column name from that lookup data source that is
      #   expected to match values in the column used as the `keycolumn` parameter in your lookup transform
      def for_import_config
        {
          source: :auth__loc__clean,
          destination: :locations,
          lookup: :auth__loc__clean_rev
        }
      end

      # Your job transformation logic always goes between `Kiba.job_segment do` and `end`
      #
      # Note that any methods that will be called by your job also need to be defined within the
      #   block passed to `Kiba.job_segment` 
      def for_import_logic
        Kiba.job_segment do
          def get_today
            Date.today.to_s
          end
          
          transform Merge::MultiRowLookup,
            keycolumn: :location_id,
            lookup: auth__loc__clean_rev,
            fieldmap: {
              reversed_location: :loc_name_reversed
            },
            constantmap: {
              update_date: get_today
            }
          transform Delete::Fields, fields: %i[location_id]
        end
      end

      # Here we are setting up everything required to run another job
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
            # using `return row` instead of `next row` here would result in a bunch of rows being dropped
            #   from your output
            next row if val.blank?

            row[:reversed_location] = val.downcase
            row
          end
        end
      end
    end
  end
end
