# Dependencies

## Gems

- net-scp
- net-ssh

## Command

以下のコマンドが実行できること

- mysqldump (mysqlの場合)

# Usage

1. このプラグインを `plugins/` 下にDL
1. Redmineの `Gemfile` に以下の gem を追記

> gem 'net-scp'
> gem 'net-ssh'

1. add crontab example:

> 30 1 * * * cd REDMINE_ROOT; /usr/bin/rake auto_backup:run

1. role setting

> Redmine's menu: Administration => Roles and permittions => role's category and checkbox

or New role e.g. "OREORE"
