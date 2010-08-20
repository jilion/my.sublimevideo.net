MySublimeVideo::Application.routes.draw do
  
  resource :protection, :only => [:show, :create]
  
  devise_for :users,
  :path => '',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :skip => [:invitations, :registrations] do
    # We need to declare these routes manually because we don't want
    # to generate GET /invitation/new and POST /invitation, so we had to skip :invitations
    scope :controller => 'devise/invitations', :as => :user_invitation do
      get :edit,   :path => '/invitation/accept', :as => 'accept'
      put :update, :path => '/invitation'
    end
    
    scope :controller => 'users/registrations', :as => :user_registration do
      get    :new,     :path => '/register'
      post   :create,  :path => '/register', :as => ''
      
      get    :edit,    :path => '/account/edit'
      put    :update,  :path => '/account/credentials'
      delete :destroy, :path => '/account'
    end
    
    %w[sign_up signup].each                { |action| match action => redirect { |p, req| "#{Rails.env.development? ? "http" : "https" }://#{req.host}/register" }, :via => :get }
    %w[log_in sign_in signin].each         { |action| match action => redirect { |p, req| "#{Rails.env.development? ? "http" : "https" }://#{req.host}/login" },    :via => :get }
    %w[log_out sign_out signout exit].each { |action| match action => redirect { |p, req| "#{Rails.env.development? ? "http" : "https" }://#{req.host}/logout" },   :via => :get }
  end
  
  resource :users, :only => :update, :path => '/account/info'
  resources :sites do
    get :state, :on => :member
  end
  resources :invoices, :only => [:index, :show]
  resource :card, :controller => "credit_cards", :as => :credit_card, :only => [:edit, :update]
  
  # match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|privacy|suspended/
  match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|privacy/
  
  scope :controller => 'tickets', :as => :ticket do
    get  :new,     :path => '/support'
    post :create,  :path => '/support', :as => ''
  end
  
  root :to => redirect("/sites")
  
  # =========
  # = Admin =
  # =========
  
  match 'admin', :to => redirect { |p, req| "#{Rails.env.development? ? "http" : "https" }://#{req.host}/admin/djs" }, :as => "admin"
  
  devise_scope :user do
    scope :controller => 'admin/users/invitations', :as => :user_invitation do # admin routes
      get  :new,    :path => '/admin/users/invitation/new'
      post :create, :path => '/admin/users/invitation', :as => ''
    end
  end
  
  devise_for :admins,
  :path => 'admin',
  :module => 'admin/admins',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :skip => [:invitations, :registrations] do
    scope :controller => 'admin/admins/invitations', :as => :admin_invitation do
      get  :new,    :path => '/admin/admins/invitation/new'
      post :create, :path => '/admin/admins/invitation', :as => ''
      get  :edit,   :path => '/admin/invitation/accept', :as => 'accept'
      put  :update, :path => '/admin/invitation'
    end
    
    scope :controller => 'admin/admins/registrations', :as => :admin_registration do
      get    :edit,    :path => '/admin/account/edit'
      put    :update,  :path => '/admin/account', :as => ''
      delete :destroy, :path => '/admin/account'
    end
    
    %w[log_in sign_in signin].each         { |action| match "admin/#{action}" => redirect { |p, req| "#{Rails.env.development? ? "http" : "https" }://#{req.host}/admin/login" },  :via => :get }
    %w[log_out sign_out signout exit].each { |action| match "admin/#{action}" => redirect { |p, req| "#{Rails.env.development? ? "http" : "https" }://#{req.host}/admin/logout" }, :via => :get }
  end
  
  namespace "admin" do
    resources :users, :only => [:index, :show]
    resources :admins, :only => [:index, :destroy]
    resources :sites, :only => [:index, :show]
    resources :delayed_jobs, :only => [:index, :show, :update, :destroy], :path => "djs"
  end
  
end