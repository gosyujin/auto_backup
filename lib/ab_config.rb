module AB
  module Config
    # read and parse Redmine config/database.yml
    def get_redmine_db_yml(yml)
      puts "#{Time.now} call #{self.class}##{__method__}"
      db_path = []

      yml_read(yml).each do |key, value|
        db_path << value
      end

      db_path.uniq
    end

    # read and parse Plugin config/setting.yml
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
