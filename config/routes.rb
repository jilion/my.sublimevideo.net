MySublimeVideo::Application.routes.draw do
  
  get "logs/show"

  resource :protection, :only => [:show, :create]
  
  devise_for :users,
  :path => '',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :controllers => { :sessions => "users/sessions" },
  :skip => [:invitations, :registrations] do
    # We need to declare these routes manually because we don't want
    # to generate GET /invitation/new and POST /invitation, so we had to skip :invitations
    resource :user_invitation, :controller => 'devise/invitations', :only => [:update],
    :path => '/invitation/accept', :path_names => { :edit => '' } do
      get :edit, :as => :accept
    end
    
    resource :user_registration, :only => [], :controller => 'users/registrations', :path => '' do
      get    :new,     :path => '/register', :as => 'new'
      post   :create,  :path => '/register'
      
      get    :edit,    :path => '/account/edit', :as => 'edit'
      put    :update,  :path => '/account/credentials'
      delete :destroy, :path => '/account'
    end
    
    %w[sign_up signup].each                { |action| match action => redirect('/register'), :via => :get }
    %w[log_in sign_in signin].each         { |action| match action => redirect('/login'),    :via => :get }
    %w[log_out sign_out signout exit].each { |action| match action => redirect('/logout'),   :via => :get }
  end
  
  resource :users, :only => :update, :path => '/account/info'
  resources :sites do
    get :state, :on => :member
  end
  resources :invoices, :only => [:index, :show]
  resource :card, :controller => 'credit_cards', :as => :credit_card, :only => [:edit, :update]
  
  # match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|privacy|suspended/
  match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|privacy/
  
  resource :ticket, :only => [:new, :create], :path => '/feedback', :path_names => { :new =>  ''}
  
  root :to => redirect("/sites")
  
  # =========
  # = Admin =
  # =========
  
  match 'admin', :to => redirect('/admin/users'), :as => 'admin'
  
  devise_scope :user do
    resource :user_invitation, :only => [], :controller => 'admin/users/invitations', :path => "" do
      get  :new,    :path => '/admin/users/invitation/new', :as => 'new'
      post :create, :path => '/admin/users/invitation'
    end
  end
  
  devise_for :admins,
  :path => 'admin',
  :module => 'admin/admins',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :skip => [:invitations, :registrations] do
    resource :admin_invitation, :only => [], :controller => 'admin/admins/invitations', :path => "" do
      get  :new,    :path => '/admin/admins/invitation/new', :as => 'new'
      post :create, :path => '/admin/admins/invitation'
      get  :edit,   :path => '/admin/invitation/accept', :as => 'accept'
      put  :update, :path => '/admin/invitation'
    end
    
    resource :admin_registration, :only => [], :controller => 'admin/admins/registrations', :path => "" do
      get    :edit,    :path => '/admin/account/edit', :as => 'edit'
      put    :update,  :path => '/admin/account'
      delete :destroy, :path => '/admin/account'
    end
    
    %w[log_in sign_in signin].each         { |action| match "admin/#{action}" => redirect('/admin/login'),  :via => :get }
    %w[log_out sign_out signout exit].each { |action| match "admin/#{action}" => redirect('/admin/logout'), :via => :get }
  end
  
  namespace "admin" do
    resources :users, :only => [:index, :show]
    resources :admins, :only => [:index, :destroy]
    resources :sites, :only => [:index, :edit, :update]
    resources :mails, :only => [:index, :new, :create]
    scope "mails", :module => "mails" do
      resources :templates, :only => [:edit, :update], :as => 'mail_templates'
      resources :logs,      :only => [:show],          :as => 'mail_logs'
    end
    resources :delayed_jobs, :only => [:index, :show, :update, :destroy], :path => "djs"
    resources :releases, :only => [:index, :create, :update]
    resources :referrers, :only => :index
  end
  
  # =======
  # = API =
  # =======
  
  namespace "api" do
    resources :invitations, :only => [:create]
  end
  
end