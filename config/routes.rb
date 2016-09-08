ActionController::Routing::Routes.draw do |map|
	map.devise_for :users
  map.root :controller => "people"
  map.clinic  '/clinic',  :controller => 'clinic', :action => 'index'
  map.create_remote  '/patient/create_remote',  :controller => 'people', :action => 'create_remote'
  map.admin  '/admin',  :controller => 'admin', :action => 'index'
  map.login  '/login',  :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.location '/location', :controller => 'sessions', :action => 'location'
  map.encounter '/encounters/new/:encounter_type', :controller => 'encounters', :action => 'new'  
  map.resource :session
  map.resources :dispensations, :collection => {:quantities => :get}
  map.resources :barcodes, :collection => {:label => :get}
  map.resources :relationships, :collection => {:search => :get}
  map.resources :programs, :collection => {:locations => :get, :workflows => :get, :states => :get}
  map.resources :encounter_types
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/'
  map.billing '/create_billing', :controller => 'billing', :action => 'create_billing'
  map.billing '/list_billing', :controller => 'billing', :action => 'list_billing'

end
