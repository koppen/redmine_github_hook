require 'redmine'

Redmine::Plugin.register :redmine_github_hook do
  name 'Redmine Github Hook plugin'
  author 'Jakob Skjerning'
  description 'This plugin allows your Redmine installation to receive Github post-receive notifications'
  version '0.1.1'
  
  settings :default => { :all_branches => "no" }, :partial => 'settings/github_settings'
  
#  project_module :whining do
#    # we need a dummy permission to enable per-project module enablement
#    permission :dummy, {:dummy => [:dummy]}, :public => true
#  end
end
