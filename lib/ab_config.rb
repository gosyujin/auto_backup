module AB
  module Config
    # REDMINE_ROOT/config/database.yml からDBの情報を読み込む
    # 重複を削除してymlのハッシュを返却
    def get_redmine_db_yml(yml)
      puts "#{Time.now} call #{self.class}##{__method__}"
      db_path = []

      yml_read(yml).each do |key, value|
        db_path << value
      end

      db_path.uniq
    end

    # PLUGIN_ROOT/config/setting.yml から情報を読み込む
    def get_plugin_settings_yml(yml)
      puts "#{Time.now} call #{self.class}##{__method__}"

      yml_read(yml)
    end

    private
    def yml_read(yml)
      str = File.open(yml).read
      YAML.load(str)
    end
  end
end
