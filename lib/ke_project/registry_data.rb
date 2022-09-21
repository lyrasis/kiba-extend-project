# frozen_string_literal: true

module KeProject
  # Central place to register the expected jobs/files used and produced by your project
  #
  # Populates file registry provided by Kiba::Extend
  module RegistryData
    module_function

    # This is what is called from your `lib/ke_project.rb` file
    def register
      # This demonstrates one relatively simple way to automatically create registry entries for all .csv files
      #   in a given directory
      # You can do `thor jobs:tagged orig` to verify that these are in your registry.
      #
      # If you are NOT doing anything fancy, you can take this line out.
      register_dir_files(dir: File.join(KeProject.datadir, 'source_system_data'), ns: 'orig')

      # If the files, jobs, and transformations all follow a pattern, you can do fancier stuff like this. For
      #   further info, see the [tips/tricks/common patterns doc page for kiba-extend](https://lyrasis.github.io/kiba-extend/file.common_patterns_tips_tricks.html#automating-repetitive-file-registry) and examples in projects linked from there. 
      #
      # If you are NOT doing anything fancy, you can take this line out.
      register_type_prep_jobs

      # The rest of the lines in this method are required!
      #
      # This populates the registry with the manually defined entries
      register_files
      
      # Calling :finalize on the registry just calls :transform and then :freeze on the registry.
      #
      # :transform transforms the file hashes below into Kiba::Extend::Registry::FileRegistryEntry objects.
      #
      # :freeze ensures data in registry is immutable for the rest of the application's run.
      #
      # If you needed to tweak the Kiba::Extend::Registry::FileRegistryEntry objects after
      #   transforming your registry hashes, before the Registry is made immutable, you
      #   can skip calling `KeProject.registry.finalize` and instead do:
      #
      # ```
      # KeProject.registry.transform
      # *your custom code here*
      # KeProject.registry.freeze
      # ```
      #
      # It is probably less trouble, however, to tweak the file registry entry hashes before they are
      #   converted into Kiba::Extend::Registry::FileRegistryEntry objects. You would do that by interacting
      #   with KeProject.registry before calling `:finalize` or `:transform` on it.
      #
      # If you need to redefine aspects of Kiba::Extend::Registry::FileRegistryEntry objects during run of
      #   jobs/dependencies, theoretically you can do that if you do not freeze the registry. I have not ever
      #   needed to do this, so I don't have patterns for it or know what the fuller implications might be.
      KeProject.registry.finalize
    end

    # Because these are supplied, not derived by the project, they do not need `creator` attributes
    #   defined. 
    def register_dir_files(dir:, ns:)
        KeProject.registry.namespace(ns) do
          Dir.children(dir).select{ |file| File.extname(file) == '.csv' }.each do |csvfile|
            key = csvfile.delete_suffix('.csv').to_sym

            register key, {
              path: File.join(dir, csvfile),
              supplied: true,
              tags: [key, ns.to_sym]
            }
          end
        end
    end
    private_class_method :register_dir_files

    def typetable_reg_entry_hash(typetable, field)
      source_key = "orig__#{typetable}".to_sym
      {
        creator: {callee: KeProject::Jobs::TypePrep, args: {source: source_key, valfield: field}},
        path: File.join(KeProject.datadir, 'working', "#{typetable}.csv"),
        tags: [:typetables, typetable],
        lookup_on: "#{field}id".to_sym
      }
    end
    private_class_method :typetable_reg_entry_hash
    
    def register_type_prep_jobs
      bind = binding
      KeProject.registry.namespace('type') do
        KeProject.type_tables.each do |typetable, field|
          # Even though :typetable_reg_entry_hash is defined immediately above, the fact is is called here
          #   nested within two `do` blocks means it is called from an unexpected scope and would fail with
          #   a method undefined error if we just did:
          #
          # `typetable_reg_entry_hash(typetable, field)`
          #
          # Because `:typetable_reg_entry_hash` is set as a private method, it will also fail with a private
          #   method called error if we do the following, since the scope it is being called from is outside
          #   the `KeProject::RegistryData` module (a module sort of equals a class in some ways in Ruby, but
          #   explaining that further is really going in the weeds):
          #
          # `KeProject::RegistryData.typetable_reg_entry_hash(typetable, field)`
          #
          #  Instead we set/pass in a Binding object in the `register_type_prep_jobs` definition, that
          #    we can then use to interact with the original scope/context. 
          register typetable, bind.receiver.send(:typetable_reg_entry_hash, *[typetable, field])
        end
      end
    end
    private_class_method :register_type_prep_jobs
    
    # Where you manually enter data about all the jobs/files in your project
    #
    # The namespace hierarchy is completely arbitrary. Set it up (or not) in a way that makes sense to you.
    #
    # Caveat/thing to consider: Thor doesn't support autocomplete, and you will end up typing these job keys
    #   a lot, so I tend to avoid nested namespaces or long namespace names/job keys.
    #
    # If you use namespaces, the unique job key is built by joining all levels of namespace, plus the registered
    #   task name, using `__` (2 underscores) as the join delimiter. 
    #
    # Documentation reference on the registry entry data format:
    #   See {https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html}
    #
    # @note I think I modeled the Kiba::Extend::Registry::FileRegistryEntry in a wrong-headed way that is making it
    #   difficult for me to handle other source/destination types. I hope to be able to re-build that in a more flexible
    #   way without drastically changing the format you would enter here, but this might be a little unstable.
    def register_files
      # This entry illustrates that entries don't have to be in a namespace at all.
      #
      # It also demonstrates all the required pieces of a job definition, busted out into granular pieces
      #   for explanation. It also demonstrates that how you name things is completely arbitrary.
      #
      # I would NOT advise using this as a pattern for setting your own jobs up, but hopefully it clarifies
      #   what the pieces are and how they relate.
      KeProject.registry.register :prep_objects, {
        path: File.join(KeProject.datadir, 'working', 'initially_processed_objects.csv'),
        creator: KeProject::EverythingExploded.method(:i_am_the_creator_method),
        desc: 'Final location authority records for import into target system',
        tags: %i[importable authority location]
      }

      # The namespace below defines registry entries set up using the structure I currently
      #   typically use when it's a normal "one entry per job with nothing very fancy" setup:
      #
      # I make a "Jobs" level to separate job definitions from transforms. In that, there is
      #   one module per registry namespace, with a submodule for each jobs defined within that module.
      #   This feels more "in the ruby spirit" of one file per class or behavior. I also find it easier
      #   to keep track of my work with this model.
      #
      # These jobs do exactly what the jobs in the previous namespace do. They just demonstrate another
      #   way to structure your code.
      KeProject.registry.namespace('locations') do
        register :clean, {
          path: File.join(KeProject.datadir, 'working', 'loc_clean.csv'),
          creator: KeProject::Jobs::Locations::Clean,
          desc: 'Location values from source system, cleaned up for further mapping',
          tags: %i[authority location]
        }
        register :clean_rev, {
          path: File.join(KeProject.datadir, 'working', 'loc_clean_and_reversed.csv'),
          creator: KeProject::Jobs::Locations::CleanRev,
          lookup_on: :location_id,
          desc: 'Location values from source system, cleaned up for further mapping',
          tags: %i[authority location]
        }

        # All the other registry entries for jobs output CSV, which is our project's
        #   default destination type.
        # This job outputs to a different destination type, so we need to tell it what
        #   destination class to use
        register :to_json, {
          path: File.join(KeProject.datadir, 'endpoint', 'locations.json'),
          dest_class: Kiba::Extend::Destinations::JsonArray,
          creator: KeProject::Jobs::Locations::ToJson,
          desc: 'Version of final locations in JSON',
          tags: %i[json authority location]
        }
      end
    end
    private_class_method :register_files
  end
end
