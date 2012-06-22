require 'dispatcher'
require 'redmine'
#require File.dirname(__FILE__) + '/lib/repository_controller_patch.rb'
require File.dirname(__FILE__) + '/lib/shell.rb'

Redmine::Plugin.register :redmine_github_hook do
  name 'Redmine Github Hook plugin'
  author 'Jakob Skjerning, Riceball LEE'
  description 'This plugin allows your Redmine support Github and install to receive Github post-receive notifications\n And show the scm url in the repository page'
  version '0.2.0'

    settings(:default => {
             :enabled  => false,
             :git_dir  => ''
             },
             :partial => 'settings/github_hook_setting')

end

ActiveRecord::Base.observers << :repository_observer
