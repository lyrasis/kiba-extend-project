# frozen_string_literal: true

module KeProject
  # Central place to register the expected jobs/files used and produced by your project
  #
  # Populates file registry provided by Kiba::Extend
  module RegistryData
    def self.register
      register_files
      KeProject.registry.transform # Transforms the file hashes below into Kiba::Extend::Registry::FileRegistryEntry objects
      KeProject.registry.freeze # Data in registry is immutable for the rest of the application's run
    end

    # Where you enter data about all the jobs/files in your project
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
    def self.register_files
      # This entry illustrates that entries don't have to be in a namespace

      KeProject.registry.register :locations, {
        path: File.join(KeProject.datadir, 'for_import', 'locations.csv'),
        creator: KeProject::TargetSystem::Locations.method(:for_import),
        desc: 'Final location authority records for import into target system',
        tags: %i[importable authority location]
      }

      # Entry for a supplied file used by jobs in your project. Supplied file means it is created by something
      #   outside this project code.
      KeProject.registry.namespace('orig') do
          register :locations, {
            path: File.join(KeProject.datadir, 'source_system_data', 'locations.csv'),
            desc: 'Original source system locations table',
            supplied: true,
            tags: %i[orig authority location]
          }
      end
      
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
    end
  end
end
