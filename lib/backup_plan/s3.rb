module BackupPlan
  class S3
    def self.upload_files
      establish_connection
      rio(Config.upload_base).each do |file|
        AWS::S3::S3Object.store(file.filename, open(file.filepath), Config.s3_bucket )
      end
    end
    
    def self.create_bucket
      establish_connection
      AWS::S3::Bucket.create Config.s3_bucket
    end
    
    private
    
    def establish_connection
      AWS::S3::Base.establish_connection!(
        :access_key_id     => Config.s3_credentials.first,
        :secret_access_key => Config.s3_credentials.last
      )
    end
  end
end