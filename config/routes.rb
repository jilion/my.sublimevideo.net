MySublimeVideo::Application.routes.draw do |map|
  
  resource :beta, :only => [:show, :create]
  
  devise_for :users, :path_names => { :sign_up => 'register', :sign_in => 'login', :sign_out => 'logout' }
  
  match 'login',    :to => 'devise/sessions#new',      :as => "new_user_session"
  match 'logout',   :to => 'devise/sessions#destroy',  :as => "destroy_user_session"
  match 'register', :to => 'devise/registrations#new', :as => "new_user_registration"
  
  %w[sign_up signup].each        { |action| match action => redirect('/register') }
  %w[log_in sign_in signin].each do |action|
    match action => redirect('/login')
    match "admin/#{action}" => redirect('/admins/login')
  end
  %w[log_out sign_out signout exit].each do |action|
    match action => redirect('/logout')
    match "admin/#{action}" => redirect('/admins/logout')
  end
  
  resources :users, :only => :update
  resources :sites do
    get :state, :on => :member
  end
  
  resources :videos, :except => :new do
    get :transcoded, :on => :member
  end
  
  resources :invoices, :only => [:index, :show]
  resource :card, :controller => "credit_cards", :as => :credit_card, :only => [:edit, :update]
  
  devise_for :admins,
  :controllers => { :registrations => "admin/registrations", :invitations => "admin/invitations" },
  :path_names => { :sign_in => 'login', :sign_out => 'logout' }
  
  match 'admin', :to => redirect('/admin/profiles'), :as => "admin"
  namespace "admin" do
    resources :users
    
    resources :sites
    
    resources :videos
    
    resources :video_profiles, :except => [:destroy], :as => :profiles, :path => "profiles" do
      resources :video_profile_versions, :only => [:show, :new, :create, :update], :as => :versions, :path => "versions"
    end
    
    resources :admins, :only => [:index, :destroy]
  end
  
  match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|docs|support/
  
  root :to => redirect('/sites')
  
  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  
  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)
  
  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  
  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end
  
  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end
  
  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end
  
  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end