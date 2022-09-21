# frozen_string_literal: true

module KeProject
  module Jobs
    module Locations
      module CleanRev
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :orig__locations,
              destination: :locations__clean_rev
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Rename::Field, from: :loc_id, to: :location_id
            transform Delete::Fields, fields: %i[updated_date]
            transform KeProject::Transforms::Locations::LocNameReverser, replace: false
          end
        end
      end
    end
  end
end
