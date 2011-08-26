module BackupPlan
  class Base
    def self.backup_all
      FileSystem.create_password_file
      FileSystem.create_encrypted_password_file
      MySQL.backup_databases
      MySQL.backup_server
      FileSystem.encrypt_files
    end
    
    def self.backup_transaction_logs
      FileSystem.create_password_file
      FileSystem.create_encrypted_password_file
      MySQL.flush_logs
      MySQL.get_binary_logs      
      FileSystem.encrypt_files
    end
  end
end