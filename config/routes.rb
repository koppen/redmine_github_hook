RedmineApp::Application.routes.draw do
  match 'github_hook' => 'github_hook#index', :via => [:post]
  match 'github_hook' => 'github_hook#welcome', :via => [:get]
end
