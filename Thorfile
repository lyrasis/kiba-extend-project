# frozen_string_literal: true

require 'bundler/setup'
require_relative 'lib/ke_project'

# Looks up the absolute path to the kiba-extend gem where it is installed on your
#   machine, and requires its Thor tasks in your project 
kiba_task_dir = "#{Gem.loaded_specs['kiba-extend'].full_gem_path}/lib/tasks/"
Dir["#{kiba_task_dir}**/*.thor"].sort.each { |f| load f }

# Loads any project-specific Thor tasks
Dir["./lib/tasks/**/*.thor"].sort.each { |f| load f }
