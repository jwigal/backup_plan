module BackupPlan
  class Base
    # wrapper for running command line options
    def self.run(binary, params = "", options = {})
      command = Cocaine::CommandLine.new(binary, params, options)
      log command.command
      command.run.gsub(/[\n\r]$/,'')
    end
    
    def self.log(command)
      logger.info command
    end
    
    def self.logger
      ::Logger.new(File.join(Config.backup_base,"backup_plan.log"))      
    end
  end
end