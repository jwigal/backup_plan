module BackupPlan
  class FileSystem
    def self.create_directories
      [BackupPlan::Config.working_base, BackupPlan::Config.upload_base, BackupPlan::Config.restore_base].each do |path|
        `mkdir -p #{path}`
      end
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
      rio(::BackupPlan::Config.working_base + "/").files(/(sql|txt)$/).all do |file|
        unless file.filename =~ /^(password|\.DS_Store)/ && file.size > 0
          puts "encrypting #{file.path}"
          commands=[
            "cp #{file.path} #{Config.upload_base}/#{file.filename}",
            "gzip #{Config.upload_base}/#{file.filename}",
            "openssl des3 -salt -k $BACKUP_PLAN_PWD " + 
              "-in #{Config.upload_base}/#{file.filename}.gz " + 
              " -out #{Config.upload_base}/#{file.filename}.gz.des3",
            "rm #{Config.upload_base}/#{file.filename}.gz",
            "rm #{file.path}"
          ]
          commands.each {|c| puts "  #{c}" ; `#{c}`}
        end
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
