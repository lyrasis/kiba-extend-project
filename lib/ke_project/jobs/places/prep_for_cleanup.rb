# frozen_string_literal: true

module KeProject::Jobs::Places::PrepForCleanup
  module_function

  def job
    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :orig__places,
        destination: :places__prep_for_cleanup
      },
      transformer: xforms
    )
  end

  def xforms
    Kiba.job_segment do
      transform do |row|
        row[:place].split("|||")
          .each do |pairstr|
            pair = pairstr.split(": ")
            row[pair[0]] = pair[1]
        end
        row
      end
      transform Clean::EnsureConsistentFields
      transform Fingerprint::Add,
        target: :fingerprint,
        fields: KeProject::Places.fingerprint_fields
      transform Delete::Fields,
        fields: :place
    end
  end
end
