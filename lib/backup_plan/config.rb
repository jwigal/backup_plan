module BackupPlan
  class Config

    def self.crypt
      @crypt ||= Crypt.new( backup_base )
    end

    def self.encryption_password
      @password ||= ActiveSupport::SecureRandom.base64(64)
    end

    def self.filename_base
      @filename_base ||= Time.now.strftime("%Y-%m-%d-%I-%M-%S")
    end

    def self.backup_base
      (config['base_folder'] || "/home/deploy/backups").gsub(/\/$/,'') + "/"
    end

    def self.working_base
      backup_base + "working"
    end

    def self.upload_base
      backup_base + "upload"
    end

    def self.restore_base
      backup_base + "restore"
    end

    def self.mysql_credentials
      [config['mysql.backup.user'], config['mysql.backup.password']]
    end
    
    def self.mysql_binary_log_base
      config['mysql.binary_log_base'] || "/var/log/mysql/mysql-bin"
    end

    def self.s3_credentials
      [config['s3.access_key'], config['s3.secret_key']]
    end

    private

    def self.config
      Settings.read("backup.yml")
    end
  end
end

