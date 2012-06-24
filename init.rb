require 'redmine'

Redmine::Plugin.register :redmine_github_hook do
  name 'Redmine Github Hook plugin'
  author 'Jakob Skjerning'
  description 'This plugin allows your Redmine installation to receive Github post-receive notifications'
  version '0.2.0'
end
