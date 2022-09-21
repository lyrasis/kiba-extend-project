# frozen_string_literal: true

module KeProject
  module Jobs
    module Locations
      module ToJson
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :locations__clean,
              destination: :locations__to_json
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Merge::ConstantValue, target: :data_source, value: 'source system'

            # example of a one-off, non-reusable, job-specific transform
            transform do |row|
              val = row[:location_type]
              # using `return row` instead of `next row` here would result in a bunch of rows being dropped
              #   from your output
              next row if val && val == 'offsite'

              name = row[:loc_name]
              row[:loc_name] = name.downcase
              row
            end
          end
        end
      end
    end
  end
end
