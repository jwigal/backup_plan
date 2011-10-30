module BackupPlan
  class FileSystem
    def self.create_directories
      [BackupPlan::Config.working_base, BackupPlan::Config.key_path, 
        BackupPlan::Config.upload_base, BackupPlan::Config.restore_base].each do |path|
        `mkdir -p #{path}`
      end
    end
    
    def self.gzip_files
      Dir.entries( BackupPlan::Config.working_base).reject{|x| x =~ /^\./}.each {|filename|  `gzip #{Config.working_base}/#{filename} && mv #{Config.working_base}/#{filename}.gz #{Config.upload_base}`}
    end

    def self.create_password_file
      rio( Config.working_base + "/password.#{Config.filename_base}.txt" ) << Config.encryption_password
    end

    def self.create_encrypted_password_file
      rio( Config.upload_base + 
        "/password.#{Config.filename_base}.txt.des3" ) << Config.crypt.encrypt_string(Config.encryption_password)
    end

    def self.encrypt_files
      puts "Working base is #{Config.working_base.inspect}"
      ENV["BACKUP_PLAN_PWD"] = Config.encryption_password
      Dir.entries( BackupPlan::Config.working_base).reject{|x| x =~ /^\./}.each do |filename|
        working_file = Config.working_base + "/#{filename}"
        upload_file = Config.upload_base + "/#{filename}"

        puts "encrypting #{filename}"
        commands=[
          "cp #{working_file} #{upload_file}",
          "gzip #{upload_file}",
          "openssl des3 -salt -k $BACKUP_PLAN_PWD " + 
            "-in #{upload_file}.gz " + 
            " -out #{upload_file}.gz.des3",
          "rm #{upload_file}.gz",
          "rm #{working_file}"
        ]
        commands.each {|c| puts ":: #{c}" ; `#{c}`}
      end
    end

    def self.decrypt_files
      password = nil

      rio(Config.restore_base).each do |file|
        if file.filename =~ /^password/
          encrypted_password = file.contents
          password = Config.crypt.decrypt_string(encrypted_password)
        end
      end
      ENV["BACKUP_PLAN_PWD"] = password

      rio(Config.restore_base).each do |file|
        unless file.filename =~ /^password/
          commands = [
            "openssl des3 -d -salt -k $BACKUP_PLAN_PWD -in #{file.path} " + 
              "-out #{file.path.gsub(/\.des3$/,'')}",
            "gunzip #{file.path.gsub(/\.des3$/,'')}",
            "rm #{file.path}"
          ]
          commands.each {|c| puts c ; `#{c}`}
        end
      end
    end
  end
end
