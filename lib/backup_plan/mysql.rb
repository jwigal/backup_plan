module BackupPlan
  class MySQL < Base
    def self.backup_databases
      databases.each do |database|
        opts = {
          :creds => credentials_string,
          :filename => [Config.working_base+"/mysql",database,Config.filename_base,"sql"].join(".") } 
        run "touch", opts[:filename]
        run "mysqldump","#{opts[:creds]} #{database} > #{opts[:filename]}"
      end
    end
    
    def self.databases
      run("mysql"," -e 'show databases' #{credentials_string} -s --skip-column-names").split("\n").reject{|x| x == "information_schema"}
    end
    
    def self.backup_server
      filename = "#{Config.working_base}/mysql.all.#{Config.filename_base}.sql"
      run "touch #{filename}"
      run "mysqldump #{credentials_string} --all-databases --flush-logs --single-transaction > #{filename}"
    end
    
    def self.credentials_string
      ENV['BACKUP_PLAN_MYSQL_PWD'] = Config.mysql_credentials.last
      " -u #{Config.mysql_credentials.first}" + 
        (Config.mysql_credentials.last ? " --password=$BACKUP_PLAN_MYSQL_PWD " : "")
    end
    
    def self.flush_logs
      run("mysqladmin #{credentials_string} flush-logs")
    end
    
    def self.get_binary_logs
      tarfile = "#{Config.working_base}/mysql.tlog.#{Config.filename_base}.tar"   
      run "cp #{Config.mysql_binary_log_base}.* #{Config.working_base}"
      run "tar -cf #{tarfile} #{Config.working_base}/*"
      run "gzip #{tarfile}"
      run "mv #{tarfile}.gz #{Config.upload_base}"
      run "rm #{Config.working_base}/*"
    end
    
    
  end
end