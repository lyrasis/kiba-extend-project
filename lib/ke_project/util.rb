# frozen_string_literal: true

module KeProject
  # Utility methods for FWM migration
  module Util
    extend self
    # Backs up working files
    def backup_working_files
      timestamp = Time.now.strftime("%y-%m-%d_%H-%M")
      backupdir = File.join(KeProject.datadir, 'backup')
      Dir.mkdir(backupdir) unless Dir.exist?(backupdir)
      workingdir = File.join(KeProject.datadir, 'working')
      
      FileUtils.cd(workingdir) do
        Dir.each_child(workingdir) do |filename|
          new_name = "#{timestamp}_#{filename}"
          FileUtils.mv(filename, "#{backupdir}/#{new_name}")
        end
      end
    end
  end
end
