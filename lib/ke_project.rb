# frozen_string_literal: true

require "kiba/extend"

# Namespace for the overall project
module KeProject
  module_function

  # @return Zeitwerk::Loader
  # Zeitwerk obviates the need to manually require project files repeatedly
  #   within the project
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

  extend Dry::Configurable

  # ## OVERRIDE KIBA::EXTEND'S DEFAULT OPTIONS
  #
  # The Kiba::Extend settings include:
  #
  # - Default settings for source and destination types (:csvopts, :source,
  #   :destination, etc)
  # - Default values used across transforms (:delim, :sgdelim, :nullvalue)
  # - Default settings for job definition and job run behavior
  #
  # See kiba-extend/lib/kiba/extend.rb for more explanation of available
  #   options. Any of the options set there (with the `setting` command) can be
  #   overridden here, however it is **highly recommended** you DO NOT
  #   override the `registry` setting
  #
  # Here we override the default Kiba::Extend :delim setting:
  Kiba::Extend.config.delim = ";"

  # ## CONFIGURE THIS PROJECT'S DEFAULTS
  #
  # Basic project-specific config includes setting the directories for your
  #   project and pre-job task behavior
  #
  # You can configure whatever settings you like or need. For more info on how
  #   config settings are defined, see
  #   https://dry-rb.org/gems/dry-configurable/main/
  #
  # For an example of config settings taken to the extreme, see
  #   https://github.com/lyrasis/kiba-tms and private client projects using it.
  #
  # Base directory for project files
  setting :datadir,
    reader: true,
    default: File.join(Bundler.root, "data")

  # If I want to be lazy I can define this to avoid typing out full directory
  #   paths. It also makes a nice example for using a constructor:
  setting :derived_dirs,
    reader: true,
    default: %w[for_import working],
    constructor: proc { |value| value.map { |dir| File.join(datadir, dir) } }
  setting :backup_dir,
    reader: true,
    default: "backup",
    constructor: proc { |value| File.join(datadir, value) }

  # You can create configs that can be used to control other behavior in
  #   your project. This is a great way to ensure consistent values are used in
  #   different contexts throughout your code. This one is used by:
  #
  # - `KeProject::RegistryData.register_type_prep_jobs`
  # - `KeProject::EverythingExploded.lookups`
  # - `KeProject::EverythingExploded.transformation_definition`
  setting :type_tables,
    reader: true,
    default: {
      object_statuses: :status,
      object_types: :type,
      location_types: :loctype
    }
  # For instance, if locations have already been cleaned up, you can use the
  #   cleaned file as a source for a job, but if clean up has not been done,
  #   use the supplied legacy location file. See
  #   `/lib/ke_project/everything_exploded.rb` for an example using this config
  #   setting.
  setting :locations_cleaned, reader: true, default: true

  # ## Override Kiba::Extend pre-job task settings
  #
  # These are below my project-specific settings to illustrate a few things:
  #
  # - Because of how I want to specify my project :derived_dirs, I need to
  #   configure it first before using it as the :pre_job_task_directories
  #   setting value
  # - `derived_dirs` is now a class method of the `KeProject` module
  # - I don't have to override all Kiba::Extend settings before setting
  #   project-specific configs
  Kiba::Extend.config.pre_job_task_run = true
  Kiba::Extend.config.pre_job_task_directories = derived_dirs
  Kiba::Extend.config.pre_job_task_backup_dir = backup_dir
  Kiba::Extend.config.pre_job_task_action = :nuke
  Kiba::Extend.config.pre_job_task_mode = :job

  # ### Re-namespacing Kiba:Extend settings
  #
  # **This is the only Kiba::Extend setting that is required to be namespaced
  #   in your project.** Do not remove or change the `:registry` setting, or
  #   Thor task running will break.
  setting :registry, default: Kiba::Extend.registry, reader: true
  #
  # Doing the following just lets us write `KeProject.delim` in our project
  #   specific code, instead of `Kiba::Extend.delim`, while ensuring a
  #   consistent default :delim is used across the board.
  setting :delim, default: Kiba::Extend.delim, reader: true
end

KeProject.loader

# If you plan on using the `thor job graph` command to generate dependency
#   graphs of jobs in your project, use this setting to control the directory
#   in which the diagram-related files will be saved. If not set in your
#   project, these files will be saved in the `data` folder of your
#   kiba-extend repo.
# @note See https://lyrasis.github.io/kiba-extend/#mermaidrenderdep for
#   the required dependencies to use this feature.
Kiba::Extend::ProjectConfig.config.graph_dir = File.join(
  Bundler.root, "data", "graphs"
)

# The following line is necessary if you wish to use
#   `Kiba::Extend::Mixins::IterativeCleanup` or the
#   `Kiba::Extend.reset_registry` method in your project.
Kiba::Extend.config.config_namespaces = [KeProject]

# This sets up your file registry. Dig into
#   `lib/ke_project/registry_data.rb` for more details on this.
#
# It is recommended you leave this here, to support any future use
#   of IterativeCleanup or `Kiba::Extend.reset_registry` in your project.
#  IterativeCleanup requires the following things need to happen in order:
#  (1) Your project gets loaded, which loads kiba-extend (and kiba-tms or any
#   other intervening application layer); (2) kiba-extend
#   `config_namespaces` gets set, so it will know where to look for
#   config modules that may extend IterativeCleanup; and (3) all job
#   entries are registered---those manually and programmatically
#   defined in `RegistryData`, and those defined by IterativeCleanup
#   mixin.
KeProject::RegistryData.register

# # The following settings are actually set in
# #   `lib/ke_project/places_cleanup.rb`,
# #   but are commented here to show an alternate place where you could set
# #   them.
# KeProject::PlacesCleanup.config.provided_worksheets = [
#   "places_cleanup_worksheet_1.csv"
# ]
# KeProject::PlacesCleanup.config.returned_files = [
#   "places_cleanup_worksheet_done_1.csv"
# ]
