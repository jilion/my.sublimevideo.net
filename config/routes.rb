MySublimeVideo::Application.routes.draw do
  
  resource :beta, :only => [:show, :create]
  
  devise_for :users,
  :path => '',
  :path_names => { :sign_up => 'register', :sign_in => 'login', :sign_out => 'logout' },
  :skip => [:invitations, :registrations] do
    scope :controller => 'admin/users/invitations', :as => :user_invitation do # admin routes
      get  :new,    :path => '/admin/users/invitation/new'
      post :create, :path => '/admin/users/invitation', :as => ''
    end
    
    scope :controller => 'devise/invitations', :as => :user_invitation do
      get :edit,   :path => '/invitation/accept', :as => 'accept'
      put :update, :path => '/invitation'
    end
    
    scope :controller => 'users/registrations', :as => :user_registration do
      get    :edit,    :path => '/account/edit'
      put    :update,  :path => '/credentials'
      delete :destroy, :path => '/account', :as => ''
    end
    
    # BEFORE PUBLIC RELEASE
    %w[sign_up signup register].each       { |action| match action => redirect('/login'),    :via => :get }
    
    # AFTER PUBLIC RELEASE
    # %w[sign_up signup].each                { |action| match action => redirect('/register'), :via => :get }
    
    %w[log_in sign_in signin].each         { |action| match action => redirect('/login'),    :via => :get }
    %w[log_out sign_out signout exit].each { |action| match action => redirect('/logout'),   :via => :get }
  end
  
  resource :users, :only => :update, :path => '/info'
  
  resources :sites do
    member do
      get :state
    end
  end
  
  resources :videos, :except => :new do
    member do
      get :transcoded
    end
  end
  
  resources :invoices, :only => [:index, :show]
  
  resource :card, :controller => "credit_cards", :as => :credit_card, :only => [:edit, :update]
  
  match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|docs|support|suspended/
  
  root :to => redirect('/sites')
  
  # =========
  # = Admin =
  # =========
  
  match 'admin', :to => redirect('/admin/djs'), :as => "admin"
  
  devise_for :admins,
  :path => 'admin',
  :module => 'admin/admins',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :skip => [:invitations, :registrations] do
    scope :controller => 'admin/admins/invitations', :as => :admin_invitation do
      get  :new,    :path => '/admin/admins/invitation/new'
      post :create, :path => '/admin/admins/invitation', :as => ''
      get :edit,    :path => '/admin/invitation/accept', :as => 'accept'
      put :update,  :path => '/admin/invitation'#, :as => ''
    end
    
    scope :controller => 'admin/admins/registrations', :as => :admin_registration do
      get    :edit,    :path => '/admin/account/edit'
      put    :update,  :path => '/admin/account', :as => ''
      delete :destroy, :path => '/admin/account', :as => ''
    end
    
    %w[log_in sign_in signin].each         { |action| match "admin/#{action}" => redirect('/admin/login'),  :via => :get }
    %w[log_out sign_out signout exit].each { |action| match "admin/#{action}" => redirect('/admin/logout'), :via => :get }
  end
  
  namespace "admin" do
    resources :users, :only => [:index, :show]
    
    resources :admins, :only => [:index, :destroy]
    
    resources :sites, :only => [:index]
    
    resources :videos, :only => [:index]
    
    resources :video_profiles, :except => [:destroy], :as => :profiles, :path => "profiles" do
      resources :video_profile_versions, :only => [:show, :new, :create, :update], :as => :versions, :path => "versions"
    end
    
    resources :delayed_jobs, :only => [:index, :show, :update, :destroy], :path => "djs"
  end
  
  # match '*path' => redirect('/')
end