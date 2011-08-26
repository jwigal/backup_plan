module BackupPlan
  class MySQL
    def backup_databases
      `for I in $(mysql -e 'show databases' #{credentials_string} -s --skip-column-names); do touch #{Config.working_base}/mysql.$I.#{Config.filename_base}.sql && mysqldump #{credentials_string} $I > "#{Config.working_base}/mysql.$I.#{Config.filename_base}.sql"; done`
    end
    
    def backup_server
      `touch #{Config.working_base}/mysql.all.#{Config.filename_base}.sql`
      `mysqldump #{credentials_string} --all-databases --flush-logs --single-transaction > #{Config.working_base}/mysql.all.#{Config.filename_base}.sql`
    end
    
    def credentials_string
      ENV['MYSQL_PWD'] = Config.mysql_credentials.last
      "-u #{Config.mysql_credentials.first}" + 
        (Config.mysql_credentials.last ? " -p$MYSQL_PWD" : "")
    end
  end
end