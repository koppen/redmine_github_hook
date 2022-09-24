# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "redmine_github_hook/version"

Gem::Specification.new do |spec|
  spec.name          = "redmine_github_hook"
  spec.version       = RedmineGithubHook::VERSION
  spec.authors       = ["Jakob Skjerning"]
  spec.email         = ["jakob@mentalized.net"]
  spec.summary       = "Allow your Redmine installation to be notified when changes have been pushed to a Github repository."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
