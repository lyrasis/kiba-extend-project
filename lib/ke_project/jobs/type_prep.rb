# frozen_string_literal: true

module KeProject
  module Jobs
    module TypePrep
      module_function

      def job(source:, valfield:)
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: source,
            destination: "type__#{source.to_s.delete_prefix('orig__')}".to_sym
          },
          transformer: xforms(valfield)
        )
      end

      def xforms(valfield)
        Kiba.job_segment do
          transform FilterRows::FieldEqualTo, action: :reject, field: valfield, value: 'undefined'
        end
      end
    end
  end
end

