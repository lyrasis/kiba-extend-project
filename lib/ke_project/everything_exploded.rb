# frozen_string_literal: true

require "date"

module KeProject
  module EverythingExploded
    module_function

    # This is the method recorded in the `creator` key of the registry entry
    #   `:prep_objects`. The first part of the `creator` value is the module
    #   hierarchy
    def i_am_the_creator_method
      Kiba::Extend::Jobs::Job.new(
        files: hash_setting_up_dependencies,
        transformer: transformation_definition
      )
    end

    # Every job needs a source and destination, each of which is a key
    #   registered in your registry.
    #
    # Here we set the source conditionally by calling the helper method
    #   `:source`.
    #
    # Lookups are optional, and you may have more than one lookup for a given
    #   job. If so, you define them like:
    #
    # ```
    # lookup: %i[a_lookup b_lookup]
    # ```
    #
    # Optionally, any registry entry that will be used as a lookup needs to have
    #   a `lookup_on` key defined. This is the field/column name from the
    #   lookup data source that will be used as the "index" for matching to
    #   values in the column used as the `keycolumn` parameter in your lookup
    #   transform. It is nice to set this in the registry entry if the same
    #   field will always serve as the lookup. You can also set the `lookup_on`
    #   per-use of the entry as a lookup. See [the "More flexible lookup
    #   file definition" section of `Kiba::Extend::Jobs`](https://lyrasis.github.io/kiba-extend/Kiba/Extend/Jobs.html#flex-lookup)
    #
    # You can also have multiple sources, which are passed in as an Array of
    #   Symbols just like multiple lookups:
    #
    # ```
    # source: %i[orig__objects pre_prepped_objects]
    # ```
    #
    # Note that if you have multiple sources and are using a CSV destination,
    #   your job definition needs to ensure that all rows it produces have the
    #   same fields, or you will get an error from the CSV writer. You can
    #   achieve this by using the `Clean::EnsureConsistentFields` transform at
    #   the end of jobs with multiple sources, or with custom transforms that
    #   might add a field to some rows, but not all rows.
    #
    # @note It _is_ redundant to have to define the destination here
    #   since the registry entry that calls this job definition itself defines
    #   the file registry key entered here as the destination. HOWEVER, there
    #   are some odd situations where you may want to conditionally set the
    #   destination to a different file registry key based on state of the
    #   project when the job is run. Also, I find it helpful to see all the
    #   files involved in the job when looking at the job definition, so it
    #   hasn't been a priority to streamline this.
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
        .map { |tt| :"type__#{tt}" }
        .select { |key| KeProject.registry.key?(key) }
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
        transform Merge::ConstantValue, target: :data_source,
          value: "source system"
      end
    end

    # You can compose job definitions from multiple `Kiba.job_segment do`
    #   blocks
    def transformation_definition
      base = [standard_transformation]
      base << constant_merge if !today_is_odd?
      base
    end

    # Your job transformation logic always goes between `Kiba.job_segment do`
    #   and `end`
    #
    # Note that the block defined in `Kiba.job_segment` is executed in the
    #   context of a `Kiba::Context` object, and NOT this module. Because of how
    #   scope works in Ruby, this means, any methods that will be called by
    #   your job need to be either:
    #
    # - defined as a Proc/Lambda within the block passed to `Kiba.job_segment`
    #   (:get_today)
    # - called with full namespace (:get_last_week)
    # - passed in with a binding object (:get_yesterday) -- this one is useful
    #   if you have done any metaprogrammy magic extension of your job
    #   definition modules, so the definition of the appropriate method may vary
    #   at runtime. The kiba-tms project uses this a lot.
    def standard_transformation
      # This sets up some Ruby magick you'll be able to access from within
      #    `Kiba.job_segment` to allow you to use other methods from this module
      bind = binding

      Kiba.job_segment do
        job_def = bind.receiver # returns KeProject::EverythingExploded module

        get_today = -> { Date.today.to_s }
        transform Merge::ConstantValues, constantmap: {
          update_date: get_today.call,
          last_week: KeProject::EverythingExploded.get_last_week,
          prev_date: job_def.send(:get_yesterday)
        }

        # It's probably a lot faster and clearer to just type out two plain
        #   Merge::MultiRowLookup and one Delete::Fields transforms, but this
        #   module exists to show weird variants you can do.
        #
        # Combined with the ability to pass parameters to job definition calls,
        #   the ability to call transforms with variables opens up some neat
        #   possibilities.
        job_def.lookups.each do |lkup|
          table = lkup.to_s
            .delete_prefix("type__")
            .to_sym
          valfield = KeProject.type_tables[table]
          idfield = :"#{valfield}id"

          transform Merge::MultiRowLookup,
            lookup: send(lkup),
            keycolumn: idfield,
            fieldmap: {valfield => valfield}
          transform Delete::Fields, fields: idfield
        end
      end
    end

    # Here we are setting up everything required to run another job. This job is
    #   not yet registered so you cannot run it.
    #
    # The application does not care that this unused stuff exists.
    #
    # Contrast this with the fact that the application currently fails if you
    #   register a job entry with a :creator value that doesn't exist.
    def some_other_job
      Kiba::Extend::Jobs::Job.new(files: foo, transformer: bar)
    end

    # It doesn't care that the source and destination keys are not registered
    #   until you register an entry with :some_other_method as the creator AND
    #   try to run that job
    def foo
      {
        source: :i_do_not_exist,
        destination: :neither_do_i
      }
    end

    def bar
      Kiba.job_segment do
        transform Merge::ConstantValue, target: :data_source,
          value: "source system"

        # example of a one-off, non-reusable, job-specific transform
        transform do |row|
          val = row.fetch(:reversed_location, nil)
          # using `return row` instead of `next row` here would result in a
          #   bunch of rows being dropped from your output
          next row if val.blank?

          row[:reversed_location] = val.downcase

          # you must always end by returning row or data will be lost
          row
        end
      end
    end
  end
end
