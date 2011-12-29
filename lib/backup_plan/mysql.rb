module BackupPlan
  class MySQL
    def self.backup_databases
      `for I in $(mysql -e 'show databases' #{credentials_string} -s --skip-column-names); do touch #{Config.working_base}/mysql.$I.#{Config.filename_base}.sql && mysqldump #{credentials_string} $I > "#{Config.working_base}/mysql.$I.#{Config.filename_base}.sql"; done`
    end
    
    def self.backup_server
      `touch #{Config.working_base}/mysql.all.#{Config.filename_base}.sql`
      c = "mysqldump #{credentials_string} --all-databases --flush-logs --single-transaction > #{Config.working_base}/mysql.all.#{Config.filename_base}.sql"
      puts c
      `#{c}`
    end
    
    def self.credentials_string
      ENV['BACKUP_PLAN_MYSQL_PWD'] = Config.mysql_credentials.last
      " -u #{Config.mysql_credentials.first}" + 
        (Config.mysql_credentials.last ? " --password=$BACKUP_PLAN_MYSQL_PWD " : "")
    end
    
    def self.flush_logs
      `mysqladmin #{credentials_string} flush-logs`
    end
    
    def self.get_binary_logs
      commands = ["sudo cp #{Config.mysql_binary_log_base}.* #{Config.working_base}",
      "sudo chown #{ENV["LOGNAME"]} #{Config.working_base}/*",
      "tar -cf #{Config.working_base}/mysql.tlog.#{Config.filename_base}.tar #{Config.working_base}/*",
      "gzip #{Config.working_base}/mysql.tlog.#{Config.filename_base}.tar",
      "mv #{Config.working_base}/mysql.tlog.#{Config.filename_base}.tar.gz #{Config.upload_base}",
      "rm #{Config.working_base}/*"
      ]     
      commands.each {|c| puts ":: #{c}" ; `#{c}`} 
    end
    
    
  end
end