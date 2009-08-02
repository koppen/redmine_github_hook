require 'redmine'

Redmine::Plugin.register :redmine_git_hook do
  name 'Redmine Git Hook plugin'
  author 'Jakob Skjerning'
  description 'This plugin allows your Redmine installation to receive Github post-receive notifications'
  version '0.0.2'
end
