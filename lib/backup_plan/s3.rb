module BackupPlan
  class S3 < Base
    def self.upload_files
      establish_connection
      ::AWS::S3::Bucket.create Config.s3_bucket
      rio(Config.upload_base).files(/^[^.]/).each do |file|
        log "Moving #{file.filename} to S3"
        file.rm if ::AWS::S3::S3Object.store(file.filename.to_s, open(file.path), Config.s3_bucket )
      end
    end

    def self.bucket
      establish_connection
      ::AWS::S3::Bucket.find(Config.s3_bucket)
    end

    def self.cleanup(days=30)
      establish_connection
      retval = []
      bucket.objects.each do |obj|
        object_date = DateTime.strptime(obj.last_modified.to_s, '%a %b %d %H:%M:%S %Z %Y')
        if (DateTime.now - object_date).to_i > 30 && object_date.day > 1 
          obj.delete
          retval << obj
          log 'Deleted: ' + obj.inspect
        end 
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