RedmineApp::Application.routes.draw do
  match 'github_hook' => 'github_hook#index', :via => [:post]
end
