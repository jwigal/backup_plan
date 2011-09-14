module BackupPlan
  class Base
    # This method will create and encrypt a password file, backup databases individually, backup the server
    # as one sql dump, and encrypt the backup files
    def self.backup_all
      FileSystem.create_encrypted_password_file
      MySQL.backup_databases
      MySQL.backup_server
      FileSystem.encrypt_files
    end
    
    # This method will create and encrypt a password file, flush the logs, get the MySQL binary logs, and encrypt
    # the backup files.
    def self.backup_transaction_logs
      FileSystem.create_encrypted_password_file
      MySQL.flush_logs
      MySQL.get_binary_logs      
      FileSystem.encrypt_files
    end
  end
end