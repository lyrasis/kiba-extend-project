# frozen_string_literal: true

module KeProject
  module Transforms
    module Locations
      # In real life, a transformation to reverse the contents of a field should not be written
      #   as a field-specific transform! You'd want to write a general Reverse::Field transform that
      #   you could pass one or more field names to. This is just a stupid, simple example.
      #
      # Every transform class should implement the interface of a Kiba transformation:
      #   - REQUIRED: a public `process` method that is passed one row of source data at a time. This method
      #     must return rows, or you will get empty output
      #   - OPTIONAL: public `initialize` method which can be used to pass in parameters controlling the
      #     transformation, and/or to set instance variables that remain the same for all rows
      #   - OPTIONAL: public `close` method
      #
      # The transformer class may also have any number of private methods to accomplish the transform.
      #
      # See [kiba wiki's entry on implementing transforms](https://github.com/thbar/kiba/wiki/Implementing-ETL-transforms) for more info, and kiba-extend and other projects using it for tons of examples. 
      #
      # TEST YOUR TRANSFORMS!!
      # See /spec/ke_project/transforms/locations/loc_name_reverser_spec.rb
      class LocNameReverser
        def initialize(replace: true)
          @loc_name_field = :loc_name
          @replace = replace
          @target = @replace ? @loc_name_field : "#{@loc_name_field}_reversed".to_sym
        end
        
        def process(row)
          value = row.fetch(@loc_name_field, nil)
          row[@target] = nil
          return row if value.blank?

          row_with_reversed_value(row, value)
        end

        private

        def row_with_reversed_value(row, value)
          row[@target] = value.reverse
          row
        end
      end
    end
  end
end
