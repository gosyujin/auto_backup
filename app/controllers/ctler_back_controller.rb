# -*- encoding: utf-8 -*-
require 'ab_ssh'
require 'ab_config'
require 'ab_fileutil'

include AB::SSH
include AB::Config
include AB::FileUtil

class CtlerBackController < ApplicationController
  unloadable

  # redmine root from REDMINE_ROOT/plugins/auto_backup/app/controller
  REDMINE_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../../../")
  # path of database.yml in redmine
  DATABASE_YML = "#{REDMINE_ROOT}/config/database.yml"
  # path of setting.yml in plugin
  SETTING_YML = File.expand_path(File.dirname(__FILE__) + "/../../config/setting.yml")

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
        @message = "failed #{params['message']}"
        @result = false
      end
    end

    # Redmine内のデータ
    @redmine_root = REDMINE_ROOT
    @dbs = AB::Config::get_redmine_db_yml(DATABASE_YML)
    if File.exist?("#{REDMINE_ROOT}/files") then
      @files = "files/"
    else
      @files = "files/ is NOT find"
    end

    # setting.ymlのデータ
    setting = AB::Config::get_plugin_settings_yml(SETTING_YML)
    @work_dir   = setting["dir"]["work"]
    @remote_dir = setting["dir"]["remote"]
    @host       = setting["ssh"]["host"]
    @port       = setting["ssh"]["port"]
    @user       = setting["ssh"]["user"]
    @password   = setting["ssh"]["password"]
    @passphrase = setting["ssh"]["passphrase"]
    @key        = setting["ssh"]["key"]
  end

  # sshのテスト
  def test
    puts "#{Time.now} call #{self.class}##{__method__}"
    setting = AB::Config::get_plugin_settings_yml(SETTING_YML)

    user = setting["ssh"]["user"]
    result = AB::SSH::test_ssh_who(setting)
    if user == result then
      redirect_to :action => "index", :notice => "success"
    else
      redirect_to :action => "index", :notice => "failed", :message => result
    end
  end

  # バックアップ実行
  def create
    puts "#{Time.now} call #{self.class}##{__method__}"

    @remote_ls = []
    # DB バックアップ
    dbs = AB::Config::get_redmine_db_yml(DATABASE_YML)
    dbs.each do |db|
      case db["adapter"]
      when "sqlite3"
        # nothing to do.
        origin_del_flag = false
      when "postgresql"
        # postgresql db dump
        origin_del_flag = true
      else
        # mysql db dump
        auth_option = "-u #{db['username']} -p#{db['password']}"
        `mysqldump #{auth_option} #{db['database']} > #{REDMINE_ROOT}/#{db['database']}`
        origin_del_flag = true
      end
      @remote_ls << backup("#{REDMINE_ROOT}/#{db['database']}", origin_del_flag)
    end

    # files/ バックアップ
    if File.exist?("#{REDMINE_ROOT}/files") then
      origin_del_flag = false
      @remote_ls << backup("#{REDMINE_ROOT}/files", origin_del_flag)
    end
  end

private
  def backup(file, origin_del_flag=false)
    puts "#{Time.now} backup start target: #{file}"
    setting = AB::Config::get_plugin_settings_yml(SETTING_YML)

    work_file = AB::FileUtil::tgz(file)
    work_file = AB::FileUtil::move_dir(work_file, setting["dir"]["work"])
    remote_ls = AB::SSH::transfer(work_file, setting)
    AB::FileUtil::rm_file(work_file)

    if origin_del_flag then
      AB::FileUtil::rm_file(file)
    end

    puts "#{Time.now} backup end"
    remote_ls
  end

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
