# このファイルを修正後に適用するためには、以下のコマンドを実行する。
#--------------------
# cd C:\Bitnami\redmine-4.2.3-1\apps\redmine\htdocs\plugins\redmine_git_hook
# bundle exec rake redmine:plugins:migrate RAILS_ENV=production
#--------------------
class CreateGitHookSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :git_hook_settings do |t|
      t.text :title
      t.boolean :is_enabled, :default => true
      t.text :project_pattern
      t.integer :remark_issue_tracker
      t.integer :remark_issue_closed_status
      t.text :keyword_to_resolve_discussion
    end
  end
end
