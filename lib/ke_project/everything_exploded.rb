# frozen_string_literal: true

require 'date'

module KeProject
  module EverythingExploded
    module_function

    # This is the method recorded in the `creator` key of the registry entry `:prep_objects`.
    # The first part of the `creator` value is the module hierarchy
    def i_am_the_creator_method
      Kiba::Extend::Jobs::Job.new(
        files: hash_setting_up_dependencies,
        transformer: transformation_definition
      )
    end

    # Every job needs a source and destination, each of which is a key registered in your
    #   registry.
    #
    # Here we set the source conditionally by calling the helper method `:source`.
    #
    # Lookups are optional, and you may have more than one lookup for a given job. If so,
    #   you define them like:
    #     lookup: %i[a_lookup b_lookup]
    #
    # Note that any registry entry that will be used as a lookup needs to have a `lookup_on` key
    #   defined in the registry entry. This is the field/column name from that lookup data source that is
    #   expected to match values in the column used as the `keycolumn` parameter in your lookup transform
    #
    # You can also have multiple sources, which are passed in as an Array of Symbols just like multiple
    #   lookups:
    #
    # ```
    # source: %i[orig__objects pre_prepped_objects]
    # ```
    #
    # Note that if you have multiple sources and are using a CSV destination, your job definition needs to
    #   ensure that all rows it produces have the same fields, or you will get an error from the CSV writer.
    #   One strategy for handling this is explained [here](https://lyrasis.github.io/kiba-extend/file.common_patterns_tips_tricks.html#joining-the-rows-of-multiple-sources-that-may-have-different-fields)
    #
    # @note It _is_ redundant to have to define the destination here since the registry entry that calls
    #   this job definition itself defines the destination. I want to refactor this out at some point, but
    #   for now it stays
    def hash_setting_up_dependencies
      {
        source: source,
        destination: :prep_objects,
        lookup: lookups
      }
    end

    # Illustrates conditionally setting source 
    def source
      if KeProject.registry.key?(:pre_prepped_objects)
        :pre_prepped_objects
      else
        :orig__objects
      end
    end

    def lookups
      base = []
      base << KeProject.type_tables
        .keys
        .map{ |tt| "type__#{tt}".to_sym }
        .select{ |key| KeProject.registry.key?(key) }
      base.flatten
    end

    # helper method called in transformation_definiton
    def get_last_week
      (Date.today - 7).to_s
    end

    # helper method called in transformation_definiton
    def get_yesterday
      (Date.today - 1).to_s
    end

    def today_is_odd?
      Date.today.day.odd?  
    end
    
    def constant_merge
      Kiba.job_segment do
        transform Merge::ConstantValue, target: :data_source, value: 'source system'
      end
    end
    
    # Your job transformation logic always goes between `Kiba.job_segment do` and `end`
    #
    # Note that the block defined in `Kiba.job_segment` is executed in the context of a `Kiba::Context` object,
    # and NOT this module. Because of how scope works in Ruby, this means, any methods that will be called by
    # your job need to be either:
    #
    # - defined within the block passed to `Kiba.job_segment` (:get_today)
    # - called with full namespace (:get_last_week)
    # - passed in with a binding object (:get_yesterday) -- this one is useful if you have done any
    #   metaprogrammy magic extension of your job definition modules, so the definition of the
    #   appropriate method may vary at runtime. The kiba-tms project uses this a lot. 
    def transformation_definition
      bind = binding
      
      Kiba.job_segment do
        job_def = bind.receiver # returns KeProject::EverythingExploded module
        
        def get_today
          Date.today.to_s
        end
        
        transform Merge::ConstantValues, constantmap: {
            update_date: get_today,
            last_week: KeProject::EverythingExploded.get_last_week,
            prev_date: job_def.send(:get_yesterday)
          }

        # It's probably a lot faster and clearer to just type out two plain Merge::MultiRowLookup
        #   and one Delete::Fields transforms, but this module exists to show weird variants you
        #   can do.
        #
        # Combined with the ability to pass parameters to job definition calls, the ability to
        #   call transforms with variables opens up some neat possibilities.
        job_def.lookups.each do |lkup|
          table = lkup.to_s
            .delete_prefix('type__')
            .to_sym
          valfield = KeProject.type_tables[table]
          idfield = "#{valfield}id".to_sym
          transform Merge::MultiRowLookup,
            lookup: send(lkup),
            keycolumn: idfield,
            fieldmap: {valfield => valfield}
          transform Delete::Fields, fields: idfield
        end
      end

      # You can compose job definitions from multiple `Kiba.job_segment do` blocks
      constant_merge if today_is_odd?

    end

    # Here we are setting up everything required to run another job. This job is not yet registered
    #   so you cannot run it.
    #
    # The application does not care that this unused stuff exists.
    #
    # Contrast this with the fact that the application currently fails if you register a job entry
    #   with a :creator value that doesn't exist.
    def some_other_job
      Kiba::Extend::Jobs::Job.new(files: foo, transformer: bar)
    end

    # It doesn't care that the source and destination keys are not registered until you register
    #   an entry with :some_other_method as the creator AND try to run that job
    def foo
      {
        source: :i_do_not_exist,
        destination: :neither_do_i
      }
    end

    def bar
      Kiba.job_segment do
        transform Merge::ConstantValue, target: :data_source, value: 'source system'

        # example of a one-off, non-reusable, job-specific transform
        transform do |row|
          val = row.fetch(:reversed_location, nil)
          # using `return row` instead of `next row` here would result in a bunch of rows being dropped
          #   from your output
          next row if val.blank?

          row[:reversed_location] = val.downcase

          # you must always end by returning row or data will be lost
          row
        end
      end
    end
  end
end
