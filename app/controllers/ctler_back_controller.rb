# -*- encoding: utf-8 -*-
begin
  require 'net/scp'
  $load_error = nil
rescue LoadError => ex
  $load_error = ex
end

class CtlerBackController < ApplicationController
  unloadable

  # redmine root from REDMINE_ROOT/plugins/auto_backup/app/controller
  REDMINE_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../../../")
  # path of database.yml in redmine
  DATABASE_YML = "#{REDMINE_ROOT}/config/database.yml"
  # path of setting.yml in plugin
  SETTING_YML = File.expand_path(File.dirname(__FILE__) + "/../../config/setting.yml")

  str = File.open(SETTING_YML).read
  setting = YAML.load(str)
  WORK_DIR   = setting["dir"]["work"]
  REMOTE_DIR = setting["dir"]["remote"]

  HOST       = setting["ssh"]["host"]
  PORT       = setting["ssh"]["port"]
  USER       = setting["ssh"]["user"]
  PASSWORD   = setting["ssh"]["password"]
  PASSPHRASE = setting["ssh"]["passphrase"]
  KEY        = setting["ssh"]["key"]

  before_filter :find_project
  menu_item :backup

  def index
    puts "#{Time.now} call #{self.class}##{__method__}"

    unless $load_error.nil? then
      @load_error = $load_error
      @result = false
    end

    # test_sshの結果
    unless params["notice"].nil? then
      case params["notice"]
      when "success"
        @message = "success"
        @result = true
      else
        @message = "failed"
        @result = false
      end
    end

    # Redmine内のデータ
    @dbs = get_dbs
    if File.exist?("#{REDMINE_ROOT}/files") then
      @files = "files/"
    else
      @files = "files/ is NOT find"
    end

    # setting.ymlのデータ
    @redmine_root = REDMINE_ROOT
    @work_dir = WORK_DIR
    @host = HOST.nil? ? "nil" : HOST
    @port = PORT.nil? ? "nil" : PORT
    @user = USER.nil? ? "nil" : USER
    @key = KEY.nil?   ? "nil" : KEY
    @password = "*"
    @passphrase = "*"
    @remote_dir = REMOTE_DIR
  end

  # sshのテスト
  def test
    puts "#{Time.now} call #{self.class}##{__method__}"

    if USER == test_ssh_who then
      redirect_to :action => "index", :notice => "success"
    else
      redirect_to :action => "index", :notice => "failed"
    end
  end

  # バックアップ実行
  def create
    puts "#{Time.now} call #{self.class}##{__method__}"

    @remote_ls = []
    # DB バックアップ
    dbs = get_dbs
    dbs.each do |db|
      case db["adapter"]
      when "sqlite3"
        # nothing to do.
      when "postgresql"
        # postgresql db dump
      else
        # mysql db dump
        `mysqldump -u #{db['username']} -p#{db['password']} #{db['database']} > #{REDMINE_ROOT}/#{db['database']}`
      end
      @remote_ls << backup("#{REDMINE_ROOT}/#{db['database']}")
    end

    # files/ バックアップ
    if File.exist?("#{REDMINE_ROOT}/files") then
      @remote_ls << backup("#{REDMINE_ROOT}/files")
    end
  end

private
  # read and parse config/database.yml
  def get_dbs
    puts "#{Time.now} call #{self.class}##{__method__}"
    db_path = []

    str = File.open(DATABASE_YML).read
    YAML.load(str).each do |key, value|
      case value["adapter"]
      when "sqlite3"
        db_path << value
      else
        # postgresql and mysql
        db_path << value
      end
    end

    db_path.uniq
  end

  def backup(file)
    puts "#{Time.now} backup start target: #{file}"
    exec_tar_flag = false
    if File.directory?(file) then
      file = tar(file)
      exec_tar_flag = true
    end
    work_file = move_dir(file, exec_tar_flag)
    work_file = compress(work_file)
    remote_ls = transfer(work_file)
    del_dir(work_file)
    puts "#{Time.now} backup end"
    remote_ls
  end

  # 対象ファイルをtarで固める
  # return: tar file path
  def tar(file)
    puts "#{Time.now} call #{self.class}##{__method__}"
    basename = File.basename(file)
    dirname = File.dirname(file)
    FileUtils.cd(dirname)
    `tar cf #{basename}.tar #{basename}`

    "#{file}.tar"
  end

  # 対象ファイルをWORK_DIRに移動またはコピーする
  # return: work_file path
  def move_dir(file, exec_tar_flag)
    puts "#{Time.now} call #{self.class}##{__method__}"
    basename = File.basename(file)
    work_file = "#{WORK_DIR}/#{basename}"
    if exec_tar_flag then
      FileUtils.mv(file, work_file)
    else
      FileUtils.cp(file, work_file)
    end

    work_file
  end

  # 対象ファイルを圧縮する
  # return: work_file path add .gz
  def compress(file)
    puts "#{Time.now} call #{self.class}##{__method__}"
    `gzip -f #{file}`

    "#{file}.gz"
  end

  # remoteへ転送する
  def transfer(file, remote_dir=REMOTE_DIR)
    puts "#{Time.now} call #{self.class}##{__method__}"
    ssh_options = ssh_option_init

    begin
      puts "#{Time.now} scp: from #{file} to #{USER}@#{HOST}:#{remote_dir}"
      Net::SSH.start(HOST, USER, ssh_options) do |session|
        # check remote directory
        exist_remote_dir = session.exec!("bash -c 'if [ -e #{remote_dir} ]; then echo exist; else echo notexist; fi'")
        if exist_remote_dir.chomp! == "notexist" then
          puts "#{Time.now} mkdir: #{remote_dir}"
          session.exec!("bash -c 'mkdir -p #{remote_dir}'")
        end

        # scp
        Net::SCP.new(session).upload!(file, remote_dir, {:verbose => 'useful'})
        str = session.exec!("bash -c 'ls -l #{remote_dir}/#{File.basename(file)}'")
        # windows-31j
        str.encode("utf-8", "windows-31j").encode("utf-8")
      end
    rescue Net::SSH::AuthenticationFailed => ex
      puts "#{ex.message}"
    rescue Errno::ECONNREFUSED => ex
      puts "#{ex.message}"
    rescue => ex
      puts "class:#{ex.class}"
      puts "message:#{ex.message}"
    end
  end

  def test_ssh_who
    puts "#{Time.now} call #{self.class}##{__method__}"
    ssh_options = ssh_option_init

    begin
      Net::SSH.start(HOST, USER, ssh_options) do |session|
        return session.exec!("bash -c 'whoami'").chomp!
      end
    rescue Net::SSH::AuthenticationFailed => ex
      puts "#{ex.message}"
    rescue Errno::ECONNREFUSED => ex
      puts "#{ex.message}"
    rescue => ex
      puts "class:#{ex.class}"
      puts "message:#{ex.message}"
    end
  end

  def ssh_option_init
    puts "#{Time.now} call #{self.class}##{__method__}"

    ssh_options = {
      :rekey_blocks_limit => 1024,
      :rekey_packet_limit => 1024,
      :compression => true
    }
    ssh_options[:port] = PORT
    ssh_options[:password] = PASSWORD
    ssh_options[:passphrase] = PASSPHRASE
    ssh_options[:keys] = KEY
    ssh_options
  end

  def del_dir(file)
    puts "#{Time.now} call #{self.class}##{__method__}"
    FileUtils.rm(file)
  end

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
