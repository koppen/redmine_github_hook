RedmineApp::Application.routes.draw do
  match "git_hook" => 'git_hook#index', :via => [:post]
  match "git_hook" => 'git_hook#welcome', :via => [:get]
  resources :git_hook_settings
end
