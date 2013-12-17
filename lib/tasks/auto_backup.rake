
namespace :auto_backup do
  PLUGIN_ROOT="./plugins/auto_backup"

  desc 'execute auto backup when this task add crontab'
  task :run => :environment do
    $LOAD_PATH << File.expand_path("#{PLUGIN_ROOT}/app/controllers")
    require 'ctler_back_controller'

    auto_backup = CtlerBackController.new
    puts auto_backup.create
  end

  desc 'remote ssh test '
  task :test => :environment do
    require 'ab_config'
    require 'ab_ssh'

    include AB::Config
    include AB::SSH

    setting = get_plugin_settings_yml("#{PLUGIN_ROOT}/config/setting.yml")
    puts "setting.yml"
    puts setting
    puts "remote hostname is ..."
    puts test_ssh_who(setting)
  end
end
