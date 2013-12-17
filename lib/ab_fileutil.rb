module AB
  module FileUtil
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

    # 対象ファイルを圧縮する
    # return: work_file path + ".gz"
    def compress(file)
      puts "#{Time.now} call #{self.class}##{__method__}"
      `gzip -f #{file}`

      "#{file}.gz"
    end

    # 対象ファイルをWORK_DIRに移動またはコピーする
    # return: work_file path
    def move_dir(file, work_dir, mv_flag)
      puts "#{Time.now} call #{self.class}##{__method__}"
      basename = File.basename(file)
      work_file = "#{work_dir}/#{basename}"
      if mv_flag then
        FileUtils.mv(file, work_file)
      else
        FileUtils.cp(file, work_file)
      end

      work_file
    end

    def del_dir(file)
      puts "#{Time.now} call #{self.class}##{__method__}"
      FileUtils.rm(file)
    end
  end
end
