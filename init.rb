Redmine::Plugin.register :auto_backup do
  name 'Auto Backup plugin'
  author 'kk_Ataka'
  description 'This plugin is auto backup Redmine DB dump and files/'
  version '0.0.1'
  url 'http://github.com/gosyujin/auto_backup.git'
  author_url 'http://github.com/gosyujin/auto_backup.git'

  # Administration => Roles and permittions => role's category and checkbox
  project_module :auto_backup do
    permission :enable, :ctler_back => [:index]
  end
  # menu
  menu :project_menu, :backup, {:controller => 'ctler_back', :action => 'index'}
end
