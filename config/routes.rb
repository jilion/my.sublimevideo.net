MySublimeVideo::Application.routes.draw do |map|
  
  resource :beta, :only => [:show, :create]
  
  %w[sign_up signup users/register].each              { |action| match action => redirect('/register'), :via => :get }
  %w[log_in sign_in signin users/login].each          { |action| match action => redirect('/login'),    :via => :get }
  %w[log_out sign_out signout exit users/logout].each { |action| match action => redirect('/logout'),   :via => :get }
  
  devise_for :users,
    :controllers => { :registrations => "users/registrations", :invitations => "admin/admins/invitations" },
    :path_names  => { :sign_up => 'register', :sign_in => 'login', :sign_out => 'logout' }
  
  match 'login',    :to => 'devise/sessions#new',      :as => "new_user_session"
  match 'logout',   :to => 'devise/sessions#destroy',  :as => "destroy_user_session"
  match 'register', :to => 'users/registrations#new',  :as => "new_user_registration"
  
  resources :users, :only => :update
  
  resources :sites do
    get :state, :on => :member
  end
  
  resources :videos, :except => :new do
    get :transcoded, :on => :member
  end
  
  resources :invoices, :only => [:index, :show]
  
  resource :card, :controller => "credit_cards", :as => :credit_card, :only => [:edit, :update]
  
  match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|docs|support|suspended/
  
  # PUBLIC RELEASE
  root :to => redirect('/sites')
  
  # =========
  # = Admin =
  # =========
  
  match 'admin', :to => redirect('/admin/djs'), :as => "admin"
  
  %w[login log_in sign_in signin].each          { |action| match "admin/#{action}" => redirect('/admin/admins/login'),  :via => :get }
  %w[logout log_out sign_out signout exit].each { |action| match "admin/#{action}" => redirect('/admin/admins/logout'), :via => :get }
  
  devise_for :admins, :path_prefix => "/admin",
    :controllers => {
      :registrations => "admin/admins/registrations",
      :invitations   => "admin/admins/invitations",
      :sessions      => "admin/admins/sessions",
      :passwords     => "admin/admins/passwords"
    },
    :path_names  => { :sign_in => 'login', :sign_out => 'logout' }
  
  match 'admin/users/invitation/new', :to => 'admin/admins/invitations#new',    :as => "new_user_invitation", :via => :get
  match 'admin/users/invitation',     :to => 'admin/admins/invitations#create', :as => "user_invitation", :via => :post
  match 'admin/users/invitation',     :to => 'admin/admins/invitations#update', :as => "user_invitation", :via => :put
  
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
  
end