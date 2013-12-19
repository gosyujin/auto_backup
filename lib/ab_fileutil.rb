require 'archive/tar/minitar'
require 'zlib'

module AB
  module FileUtil
    # 対象ファイルをtgzで固める
    # return: tar file path
    def tgz(file)
      puts "#{Time.now} call #{self.class}##{__method__}"
      basename = File.basename(file)
      dirname = File.dirname(file)
      FileUtils.cd(dirname)

      tgz = Zlib::GzipWriter.new(File.open("#{basename}.tgz", 'wb'))
      Archive::Tar::Minitar.pack(basename, tgz)
#      tgz.close

      "#{file}.tgz"
    end

    # 対象ファイルをWORK_DIRに移動する
    # return: work_file path
    def move_dir(file, work_dir)
      puts "#{Time.now} call #{self.class}##{__method__}"
      basename = File.basename(file)
      work_file = "#{work_dir}/#{basename}"
      FileUtils.mv(file, work_file)

      work_file
    end

    # 対象ファイルを削除する
    def rm_file(file)
      puts "#{Time.now} call #{self.class}##{__method__}"
      FileUtils.rm(file)
    end
  end
end
