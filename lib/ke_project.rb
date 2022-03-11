# frozen_string_literal: true

require 'kiba/extend'
require 'zeitwerk'

# Namespace for the overall project
module KeProject
  extend Dry::Configurable

  class << self
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
              @loader
            end

    # Will reload project code. Useful when working in console
    def reload!
      @loader.reload
    end
  end

  self.loader
  
  # OVERRIDE KIBA::EXTEND'S DEFAULT OPTIONS
  # See kiba-extend/lib/kiba/extend.rb for more explanation of available options. Any of the options set there
  #   (with the `setting` command) can be overridden here, however it is **highly recommended** you DO NOT
  #   override the `registry` setting

  # By default, kiba-extend downcases and symbolizes CSV headers, but does not apply any CSV content
  #   converters. Uncommenting this will cause the `stripplus` and `nulltonil` CSV converters defined
  #   in kiba-extend to be applied to all your CSV data
  # Kiba::Extend.config.csvopts = {headers: true,
  #                                header_converters: [:symbol, :downcase],
  #                                converters: %i[stripplus nulltonil]}

  # kiba-extend's default delimiter for the primary/initial split/join level in data is `;`. A bunch of tests
  #   were initially written using that delimiter. Many transforms that need a `sep` or `delim` argument default
  #   to the Kiba::Extend.delim value if not explicitly set when you call a transformation. Overriding this with
  #   your project's delimiter means it will be used.
  Kiba::Extend.config.delim = '|'

  # kiba-extend's default destination is Kiba::Extend::Destinations::CSV. This means if we want to use that
  #   destination for everything (or most things), we don't have to specify it explicitly in every job
  #   we register in `lib/ke_project/registry_data.rb`. If we want to use a different destination by default:
  # Kiba::Extend.config.destination = Kiba::Extend::Destinations::JsonArray

  # kiba-extend defaults to normal verbosity of STDOUT when running jobs, but while you are developing
  #   a project, the debug level can be helpful
  # Kiba::Extend.config.job.verbosity = :debug

  # CONFIGURE KEPROJECT'S DEFAULTS
  # We overrode this above so we can avoid typing out the `delim` or `sep` keyword argument when we
  #   set up our transforms. We set it locally so we can type `KeProject.delim` where we need it in
  #   our code instead of `Kiba::Extend.delim`. You could also go wild and set it to a different string
  #   value here if you wanted to. 
  setting :delim, default: Kiba::Extend.delim, reader: true

  # More minimization of typing...
  setting :csvopts, default: Kiba::Extend.csvopts, reader: true
  
  # Example to show you can create whatever options you need
  #   If your project's source data separates values with ';; ', this may be useful
  # The `reader: true` part lets you call: `KeProject.source_data_delim`
  #   If we omitted the `reader: true`, we have to call: `KeProject.config.source_data_delim`
  setting :source_data_delim, default: ';; ', reader: true
  
  # Base directory for project files
  setting :datadir, default: File.expand_path('data'), reader: true
  
  # :job or :none
  #   :job - regenerates all dependency files on every run by moving all existing files in working directory
  #     to backup directory. This mode is recommended during development when you want any change in the
  #     dependency chain to get picked up.
  #   :none - only regenerates missing dependency files. Useful when your data is really big and/or your
  #     jobs are more stable
  setting :backup_mode, default: :job, reader: true

  # File registry - best to just leave this as-is
  setting :registry, default: Kiba::Extend.registry, reader: true
  
  KeProject::Util.backup_working_files if KeProject.backup_mode == :job

  KeProject::RegistryData.register
end
