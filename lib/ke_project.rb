# frozen_string_literal: true

require 'kiba/extend'

# Namespace for the overall project
module KeProject
  module_function

  # @return Zeitwerk::Loader
  # Zeitwerk obviates the need to manually require project files repeatedly within the project
  def loader
    @loader ||= setup_loader
  end

  # Creates Zeitwerk::Loader, making it reloadable
  private def setup_loader
            @loader = Zeitwerk::Loader.for_gem
            @loader.enable_reloading
            @loader.setup
            @loader.eager_load
            @loader
          end

  # Will reload project code. Useful when working in console
  def reload!
    @loader.reload
  end

  loader
  
  extend Dry::Configurable
  # ## OVERRIDE KIBA::EXTEND'S DEFAULT OPTIONS
  #
  # The Kiba::Extend settings include:
  #
  # - Default settings for source and destination types (:csvopts, :source, :destination, etc)
  # - Default values used across transforms (:delim, :sgdelim, :nullvalue)
  # - Default settings for job definition and job run behavior
  # 
  # See kiba-extend/lib/kiba/extend.rb for more explanation of available options. Any of the options set there
  #   (with the `setting` command) can be overridden here, however it is **highly recommended** you DO NOT
  #   override the `registry` setting
  #
  # Here we override the default Kiba::Extend :delim setting:
  Kiba::Extend.config.delim = ';'

  # ## CONFIGURE THIS PROJECT'S DEFAULTS
  #
  # Basic project-specific config includes setting the directories for your project and pre-job task
  #   behavior
  #
  # You can configure whatever settings you like or need. For more info on how config settings are defined,
  #   see https://dry-rb.org/gems/dry-configurable/main/
  #
  # For an example of config settings taken to the extreme, see
  #   https://github.com/lyrasis/kiba-tms and private client projects using it.
  #
  # Base directory for project files
  setting :datadir, default: File.expand_path('data'), reader: true
  #
  # If I want to be lazy I can define this to avoid typing out full directory paths. It also makes a nice
  #   example for using a constructor:
  setting :derived_dirs,
    default: %w[for_import working],
    reader: true,
    constructor: proc{ |value| value.map{ |dir| File.join(datadir, dir) } }
  setting :backup_dir,
    default: 'backup',
    reader: true,
    constructor: proc{ |value| File.join(datadir, value) }
  # You can create configs that can be hooked into to control other behavior in your project.
  #   This one is used by the `KeProject::RegistryData.register_type_prep_jobs`.
  setting :type_tables,
    default: {
      object_statuses: :status,
      object_types: :type,
      location_types: :loctype
    },
    reader: true
  # For instance,
  #   if locations have already been cleaned up, you can use the cleaned file as a source for a job,
  #   but if clean up has not been done, use the supplied legacy location file. See
  #   `/lib/ke_project/everything_exploded.rb` for an example using this config setting.
  setting :locations_cleaned, default: true, reader: true
  
  # ## Override Kiba::Extend pre-job task settings
  # 
  # These are below my project-specific settings to illustrate a few things:
  #
  # - Because of how I want to specify my project :derived_dirs, I need to configure it first before
  #   using it as the :pre_job_task_directories setting value
  # - `derived_dirs` is now a class method of the `KeProject` module
  # - I don't have to override all Kiba::Extend settings before setting project-specific configs
  Kiba::Extend.config.pre_job_task_run = true
  Kiba::Extend.config.pre_job_task_directories = derived_dirs
  Kiba::Extend.config.pre_job_task_backup_dir = backup_dir
  Kiba::Extend.config.pre_job_task_action = :nuke
  Kiba::Extend.config.pre_job_task_mode = :job

  # ### Re-namespacing Kiba:Extend settings
  #
  # **This is the only Kiba::Extend setting that is required to be namespaced in your project.** Do not
  #   remove or change the `:registry` setting, or Thor task running will break.
  setting :registry, default: Kiba::Extend.registry, reader: true
  #
  # Doing the following just lets us write `KeProject.delim` in our project specific code, instead of
  #   `Kiba::Extend.delim`, while ensuring a consistent default :delim is used across the board.
  setting :delim, default: Kiba::Extend.delim, reader: true

  
  # This sets up your file registry. Dig into `lib/ke_project/registry_data.rb` for more details on this.
  KeProject::RegistryData.register
end
