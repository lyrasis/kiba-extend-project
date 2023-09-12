# frozen_string_literal: true

module KeProject::Places
  module_function

  extend Dry::Configurable

  setting :fingerprint_fields,
    default: %i[place country state county city],
    reader: true
end
