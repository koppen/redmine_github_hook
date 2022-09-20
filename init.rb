require "redmine"

Redmine::Plugin.register :redmine_github_hook do
  name "Redmine Github Hook plugin"
  author "Jakob Skjerning"
  description "This plugin allows your Redmine installation to receive Github post-receive notifications"
  url "https://github.com/koppen/redmine_github_hook"
  author_url "http://mentalized.net"
  version RedmineGithubHook::Version
end
