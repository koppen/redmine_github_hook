require "redmine"

Redmine::Plugin.register :redmine_git_hook do
  name "Redmine Git Hook plugin"
  author "Redmine Power"
  description "This plugin allows you can automatically synchronize your Git and Redmine repositories and also automatically link comments on Git merge request to Redmine issues."
  url "https://github.com/RedminePower/redmine_git_hook"
  author_url "https://www.redmine-power.com/"
  version RedmineGitHook::VERSION

  menu :admin_menu, :git_hook_settings,
  { :controller => 'git_hook_settings', :action => 'index' },
  :caption => :gh_label_git_hook_setting,
  :html => { :class => 'icon icon-git_hook_setting'},
  :if => Proc.new { User.current.admin? }

end
