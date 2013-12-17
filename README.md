# Dependencies

## Gems

- net-scp
- net-ssh

## Command

以下のコマンドへのPATHが通っていること。

- mysqlの場合
  - mysqldump

# Usage

1. このプラグインを `plugins/` 下にDL
1. REDMINE_ROOT で `bundle install`
1. crontab に以下の Rake タスクを追加(rake する前に REDMINE_ROOT へ移動する)

> 30 1 * * * cd REDMINE_ROOT; /usr/bin/rake auto_backup:run

1. role setting

> Redmine's menu: Administration => Roles and permittions => role's category and checkbox

or New role e.g. "OREORE"
