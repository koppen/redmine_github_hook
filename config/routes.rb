ActionController::Routing::Routes.draw do |map|
  map.connect 'github_hook', :controller => 'github_hook', :action => 'index',
              :conditions => {:method => :post}
end
