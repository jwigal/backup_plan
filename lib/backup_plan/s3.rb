module BackupPlan
  class S3
    def self.upload_files
      establish_connection
      ::AWS::S3::Bucket.create Config.s3_bucket
      rio(Config.upload_base).files(/^[^.]/).each do |file|
        puts "Moving #{file.filename} to S3"
        file.rm if ::AWS::S3::S3Object.store(file.filename.to_s, open(file.path), Config.s3_bucket )
      end
    end
        
    private
    
    def self.establish_connection
      ::AWS::S3::Base.establish_connection!(
        :access_key_id     => Config.s3_credentials.first,
        :secret_access_key => Config.s3_credentials.last
      )
    end
  end
end