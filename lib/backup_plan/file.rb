module BackupPlan
  class File
    def self.create_password_file
      rio( Config.working_base + "/password.#{Config.filename_base}.txt" ) << Config.encryption_password
    end

    def self.create_encrypted_password_file
      rio( Config.upload_base + 
        "/password.#{Config.filename_base}.txt.des3" ) << Config.crypt.encrypt_string(Config.encryption_password)
    end

    def self.encrypt_files
      rio(Config.working_base).each do |file|
        unless file.filename =~ /^password/
          puts "encrypting #{file.path}"
          commands=[
            "cp #{file.path} #{Config.upload_base}/#{file.filename}",
            "openssl des3 -salt -k \"#{Config.encryption_password}\" -in #{Config.upload_base}/#{file.filename} " + 
              " -out #{Config.upload_base}/#{file.filename}.des3",
            "gzip #{Config.upload_base}/#{file.filename}.des3",
            "rm #{Config.upload_base}/#{file.filename}"          
          ]
          commands.each {|c| puts c ; `#{c}`}
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

      rio(Config.restore_base).each do |file|
        unless file.filename =~ /^password/
          commands = [
            "gunzip #{file.path}",
            "openssl des3 -d -salt -k \"#{password}\" -in #{file.path.gsub(/.gz/,'')} " + 
              "-out #{file.path.gsub(/\.des3\.gz$/,'')}",
            "rm #{file.path.gsub(/\.gz/,'')}"
          ]
          commands.each {|c| puts c ; `#{c}`}
        end
      end
    end
  end
end