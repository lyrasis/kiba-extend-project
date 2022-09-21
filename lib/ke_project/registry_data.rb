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
      # Depending on your needs, there are many flexible options leveraging the ability to
      #   define job definition modules that can be called with parameters, and writing custom code
      #   to define job registry entries dynamically. For examples of doing some of these more complex,
      #   metaprogrammy things, see the
      #   [tips/tricks/common patterns doc page for kiba-extend](https://lyrasis.github.io/kiba-extend/file.common_patterns_tips_tricks.html#automating-repetitive-file-registry) and examples in projects linked from there. 
      register_dir_files(dir: File.join(KeProject.datadir, 'source_system_data'), ns: 'orig')
      # This populates the registry with the manually defined entries
      register_files
      # Transforms the file hashes below into Kiba::Extend::Registry::FileRegistryEntry objects and
      #   ensures data in registry is immutable for the rest of the application's run
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
    
    # Where you manually enter data about all the jobs/files in your project
    #
    # The namespace hierarchy is completely arbitrary. Set it up (or not) in a way that makes sense to you.
    #
    # The first entry shows that you don't need to use namespaces at all.
    #
    # If you do use namespaces, the unique job key is built by joining all levels of namespace, plus the registered
    #   task name, using `__` (2 underscores) as the join delimiter. 
    #
    # Documentation reference on the registry entry data format:
    #   See {https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html}
    #
    # @note I think I modeled the Kiba::Extend::Registry::FileRegistryEntry in a wrong-headed way that is making it
    #   difficult for me to handle other source/destination types. I hope to be able to re-build that in a more flexible
    #   way without drastically changing the format you would enter here, but this might be a little unstable.
    def register_files
      # This entry illustrates that entries don't have to be in a namespace
      KeProject.registry.register :locations, {
        path: File.join(KeProject.datadir, 'for_import', 'locations.csv'),
        creator: KeProject::TargetSystem::Locations.method(:for_import),
        desc: 'Final location authority records for import into target system',
        tags: %i[importable authority location]
      }
      
      # This namespace demonstrates one way of organizing job definition code: one module per registry
      #   namespace, with multiple jobs defined within that module. I have moved away from this
      #   model in my projects, since, as jobs get more complex, the files defining them get really
      #   long and it is hard to navigate in them
      KeProject.registry.namespace('auth') do
        namespace('loc') do
          register :clean, {
            path: File.join(KeProject.datadir, 'working', 'loc_clean.csv'),
            creator: KeProject::SourceSystem::Locations.method(:clean),
            desc: 'Location values from source system, cleaned up for further mapping',
            tags: %i[authority location]
          }
          register :clean_rev, {
            path: File.join(KeProject.datadir, 'working', 'loc_clean_and_reversed.csv'),
            creator: KeProject::SourceSystem::Locations.method(:clean_reverse),
            lookup_on: :location_id,
            desc: 'Location values from source system, cleaned up for further mapping',
            tags: %i[authority location]
          }

          # All the other registry entries for jobs output CSV, which is our project's
          #   default destination type.
          # This job outputs to a different destination type, so we need to tell it what
          #   destination class to use
          register :json, {
            path: File.join(KeProject.datadir, 'endpoint', 'locations.json'),
            dest_class: Kiba::Extend::Destinations::JsonArray,
            creator: KeProject::TargetSystem::Locations.method(:for_endpoint),
            desc: 'Version of final locations in JSON',
            tags: %i[json authority location]
          }
        end
      end

      # This namespace demonstrates another way of organizing job definition code: one module per registry
      #   namespace, with a submodule for each jobs defined within that module. This feels more
      #   "in the ruby spirit" of one file per class or behavior. I also find it easier to keep track
      #   of my work with this model.
      #
      # These jobs do exactly what the jobs in the previous namespace do. They just demonstrate another
      #   way to structure your code.
      KeProject.registry.namespace('authority') do
        namespace('locs') do
          register :clean, {
            path: File.join(KeProject.datadir, 'working', 'loc_clean.csv'),
            creator: KeProject::SourceSystem::Locations.method(:clean),
            desc: 'Location values from source system, cleaned up for further mapping',
            tags: %i[authority location]
          }
          register :clean_rev, {
            path: File.join(KeProject.datadir, 'working', 'loc_clean_and_reversed.csv'),
            creator: KeProject::SourceSystem::Locations.method(:clean_reverse),
            lookup_on: :location_id,
            desc: 'Location values from source system, cleaned up for further mapping',
            tags: %i[authority location]
          }

          # All the other registry entries for jobs output CSV, which is our project's
          #   default destination type.
          # This job outputs to a different destination type, so we need to tell it what
          #   destination class to use
          register :json, {
            path: File.join(KeProject.datadir, 'endpoint', 'locations.json'),
            dest_class: Kiba::Extend::Destinations::JsonArray,
            creator: KeProject::TargetSystem::Locations.method(:for_endpoint),
            desc: 'Version of final locations in JSON',
            tags: %i[json authority location]
          }
        end
      end
    end
    private_class_method :register_files
  end
end
