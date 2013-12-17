#begin
  require 'net/scp'
#  $load_error = nil
#rescue LoadError => ex
#  $load_error = ex
#end

module AB
  module SSH
    def test_ssh_who(setting)
      puts "#{Time.now} call #{self.class}##{__method__}"
      return exec_ssh(:ssh, "whoami", setting)
    end

    # remoteへ転送す縷K
    def transfer(file, setting)
      puts "#{Time.now} call #{self.class}##{__method__}"

      remote_dir = setting["dir"]["remote"]
      # check remote directory
      #   if [ -e #{remote_dir} ]; then
      #     echo exist
      #   else
      #     echo notexist
      #   fi
      check_exist = "if [ -e #{remote_dir} ]; then echo exist; else echo notexist; fi"
      exist_remote_dir = exec_ssh(:ssh, check_exist, setting)
      if exist_remote_dir == "notexist" then
        puts "#{Time.now} mkdir: #{remote_dir}"
        exec_ssh(:ssh, "mkdir -p #{remote_dir}", setting)
      end
      # scp
      exec_ssh(:scp, file, setting)
      str = exec_ssh(:ssh, "ls -l #{remote_dir}/#{File.basename(file)}", setting)
      # windows-31j
      str.encode("utf-8", "windows-31j").encode("utf-8")
    end

    private
    # args: when command = ssh then args = exec command
    # args: when command = scp then args = scp file path
    def exec_ssh(command, args, setting)
      puts "#{Time.now} call #{self.class}##{__method__}"
      ssh_options = ssh_option_init(setting)

      user = setting["ssh"]["user"]
      host = setting["ssh"]["host"]
      remote_dir = setting["dir"]["remote"]

      Net::SSH.start(host, user, ssh_options) do |session|
        case command
        when :scp
          puts "#{Time.now} scp: from #{args} to #{user}@#{host}:#{remote_dir}"
          return Net::SCP.new(session).upload!(args, remote_dir, {:verbose => 'useful'})
        when :ssh
          return session.exec!("bash -c '#{args}'").chomp!
        end
      end
    rescue Net::SSH::AuthenticationFailed => ex
      puts "1"
      puts "class:#{ex.class} #{ex.message}"
      return ex.class
    rescue Errno::ECONNREFUSED => ex
      puts "2"
      puts "class:#{ex.class} #{ex.message}"
    rescue => ex
      puts "3"
      puts "class:#{ex.class} #{ex.message}"
    end

    def ssh_option_init(setting)
      puts "#{Time.now} call #{self.class}##{__method__}"

      ssh_options = {
        :rekey_blocks_limit => 1024,
        :rekey_packet_limit => 1024,
        :compression => true
      }
      ssh_options[:port] = setting["ssh"]["port"]
      ssh_options[:password] = setting["ssh"]["password"]
      ssh_options[:passphrase] = setting["ssh"]["passphrase"]
      ssh_options[:keys] = setting["ssh"]["key"]
      ssh_options
    end
  end
end
