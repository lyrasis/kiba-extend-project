# frozen_string_literal: true

module KeProject
  module Jobs
    module Locations
      module Clean
        module_function

        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :orig__locations,
              destination: :locations__clean,
              lookup: %i[
                         type__location_types
                         locations__clean_rev
                        ]
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Rename::Field, from: :loc_id, to: :location_id
            transform KeProject::Transforms::Locations::LocNameReverser, replace: true
            transform Merge::MultiRowLookup,
              lookup: type__location_types,
              keycolumn: :loctypeid,
              fieldmap: {location_type: :loctype}
            transform Delete::Fields, fields: %i[updated_date loctypeid]
            transform Merge::MultiRowLookup,
              lookup: locations__clean_rev,
              keycolumn: :location_id,
              fieldmap: {unreversed_location: :loc_name}
          end
        end
      end
    end
  end
end
