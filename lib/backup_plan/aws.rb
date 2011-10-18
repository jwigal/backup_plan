module BackupPlan
  class AWS
    def self.instance_id
      `curl -s http://169.254.169.254/latest/meta-data/instance-id`.gsub(/[\n\r]/,'')
    end
    
    def self.file_system_mountpoint
      `$(cat /etc/fstab | grep xfs | awk '{ print $1}')`.gsub(/[\n\r]/,'')
    end

    def self.virtual_mountpoint
      `$(cat /etc/fstab | grep xfs | awk '{ print $2}')`.gsub(/[\n\r]/,'')
    end
    
    def self.volume_id
      `$(ec2-describe-volumes -C #{Config.aws_cert_path} -K #{Config.aws_key_path} | grep "#{instance_id}" | grep "#{file_system_mountpoint}" | awk '{print $2}')`.gsub(/[\n\r]/,'')
    end
    
    def self.backup_name
      ["Daily snapshot", instance_id, volume_id].join(" ")
    end
    
    def self.snapshot_description
      @description ||= `#{backup_name} $(date +'%Y-%m-%d %H-%M-%S')`.gsub(/[\n\r]/,'')
    end
    
    def self.volumes
      `ec2-describe-volumes -C $EC2_CERT -K $EC2_PRIVATE_KEY | grep ${MY_INSTANCE_ID} | awk '{ print $2 }'`.split(/[^a-z0-9-]+/)
    end
    
    
    def self.mysql_credentials_string
      ENV['BACKUP_PLAN_MYSQL_PWD'] = Config.mysql_credentials.last
      " --mysql-username #{Config.mysql_credentials.first}" + 
        (Config.mysql_credentials.last ? " --mysql-password $BACKUP_PLAN_MYSQL_PWD " : "")
    end
    
    def self.consistent_snapshot_command
      ["ec2-consistent-snapshot", 
        "--mysql", mysql_credentials_string, 
        "--freeze-filesystem",  virtual_mountpoint,
        "--region", Config.aws_region,
        "--description", "\"#{snapshot_description}\"",
        volume_id 
        ].join(" ")
    end
    
    
    def self.cleanup_snapshots_command(volume, keep)
      [ "ec2-describe-snapshots -C $EC2_CERT -K $EC2_PRIVATE_KEY",
        "sort -r -k #{keep}",
        "grep #{volume}",
        "grep \"#{backup_name}\"",
        "sed 1,6d",
        "awk '{print \"Deleting snapshot: \" $2}; system(\"ec2-delete-snapshot \" $2)'"
        ].join(" | ")
    end
    
    def self.cleanup_snapshots(keep=5)
      volumes.each {|v|  `#{cleanup_snapshots_command(v, keep)}`}
    end
    
    def self.mysql_consistent_snapshot
      ENV["EC2_PRIVATE_KEY"] = Config.aws_key_path
      ENV["EC2_CERT"] = Config.aws_cert_path
      echo "Instance: #{instance_id}"
      echo "FS Mount: #{file_system_mountpoint}"
      echo "Virtual Mount: #{virtual_mountpoint}"
      echo "XFS Volume: #{volume_id}"
      echo "Snapshot: #{snapshot_description}"
      echo "Volume List: #{volumes.join(", ")}"
      `#{consistent_snapshot_command}`
    end
  end
end