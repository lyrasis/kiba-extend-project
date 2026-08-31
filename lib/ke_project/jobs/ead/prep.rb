# frozen_string_literal: true

module KeProject
  module Jobs
    module Ead
      # This job demonstrates kiba-extend's support of XML pipelines.
      # The code below uses Kiba::Extend::Sources::XmlDir to read
      # a directory of XML files (in the supplied fixtures, that's
      # just one EAD). Then it uses a simple transform that's meant
      # to illustrate a reusable pattern for XML work with kiba-extend.
      # The transform is in KeProject::Transforms::Ead::SelectElements.
      #
      # Notice that we use XmlJob instead of Job. That's to account for
      # the fact that XML Documents aren't per-row Hash records and
      # need to be specially handled.
      module Prep
        module_function

        def job
          Kiba::Extend::Jobs::XmlJob.new(
            files: {
              source: :orig__ead,
              destination: :ead__prep
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform KeProject::Transforms::Ead::SelectElements
          end
        end
      end
    end
  end
end
