# frozen_string_literal: true

module KeProject::PlacesCleanup
  module_function

  extend Dry::Configurable

  setting :base_job, default: :places__prep_for_cleanup, reader: true
  setting :job_tags, default: %i[place cleanup], reader: true
  setting :worksheet_add_fields,
    default: %i[proximity uncertainty],
    reader: true

  def fingerprint_fields
    KeProject::Places.fingerprint_fields
  end

  setting :fingerprint_flag_ignore_fields,
    default: [:place],
    reader: true

  def worksheet_field_order
    fingerprint_fields - fingerprint_flag_ignore_fields
  end

  extend Kiba::Extend::Mixins::IterativeCleanup
end

# Extending `IterativeCleanup` in the above module definition defines
#   the following config settings with empty arrays as the default
#   value, and constructor logic to generate full file paths from the
#   file names. The "Defines settings in the extending config module"
#   section at the link below explains these settings and their
#   assumptions:
#
# https://lyrasis.github.io/kiba-extend/Kiba/Extend/Mixins/IterativeCleanup.html
#
# When we actually have files to record, we set the setting value, *from
#   outside* the body of the module definition.
#
# If I want to see all my project config in one place, I can set these from the
#   end of `lib/ke_project.rb`. If it makes more sense to me to handle all the
#   config/settings for place cleanup in this file, I can set them here.
KeProject::PlacesCleanup.config.provided_worksheets = [
  "places_cleanup_worksheet_1.csv"
]
KeProject::PlacesCleanup.config.returned_files = [
  "places_cleanup_worksheet_done_1.csv"
]
