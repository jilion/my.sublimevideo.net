MySublimeVideo::Application.routes.draw do

  devise_for :users,
  :path => '',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :controllers => { :sessions => "users/sessions" },
  :skip => [:invitations, :registrations] do
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
  match '/password/validate' => "users/passwords#validate", :via => :post
  match '/invitation/accept' => redirect('/register'), :via => :get

  resource :users, :only => :update, :path => '/account/info'
  resources :sites, :except => :show do
    member do
      get :state
      get :code
      # get :usage
    end
    resource :plan, :only => [:edit, :update, :destroy]
    resources :invoices, :only => :index
  end
  resource :card, :controller => 'credit_cards', :as => :credit_card, :only => [:edit, :update]
  match '/transaction/callback' => "transactions#callback", :via => :post
  resources :invoices, :only => :show do
    put :pay, :on => :member
  end

  match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|privacy|suspended/
  match 'r/:type/:token', :to => 'referrers#redirect', :via => :get, :type => /c/, :token => /[a-z0-9]{8}/

  resource :ticket, :only => [:new, :create], :path => '/support', :path_names => { :new =>  '' }
  match '/feedback' => redirect('/support'), :via => :get

  root :to => redirect("/sites")

  # =========
  # = Admin =
  # =========

  match 'admin', :to => redirect('/admin/dashboard'), :as => 'admin'

  devise_for :admins,
  :path => 'admin',
  :module => 'admin/admins',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :skip => [:invitations, :registrations] do
    resource :admin_invitation, :only => [], :controller => 'admin/admins/invitations', :path => "" do
      get  :new,    :path => '/admin/admins/invitation/new', :as => 'new'
      post :create, :path => '/admin/admins/invitation'
      get  :edit,   :path => '/admin/invitation/accept', :as => 'accept'
      put  :update, :path => '/admin/admins/invitation'
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
    resource  :dashboard, :only => :show
    resources :users,     :only => [:index, :show]
    resources :sites,     :only => [:index, :show, :edit, :update] do
      member do
        put :sponsor
      end
    end
    resources :referrers, :only => :index
    resources :invoices,  :only => [:index, :show, :edit] do
      member do
        put :retry_charging
        put :cancel_charging
      end
    end
    resources :plans,     :only => [:index, :new, :create]
    resources :admins,    :only => [:index, :destroy]
    resources :mails,     :only => [:index, :new, :create]
    scope "mails" do
      resources :mail_templates, :only => [:new, :create, :edit, :update], :path => "templates"
      resources :mail_logs,      :only => :show,                           :path => "logs"
    end
    resources :releases,     :only => [:index, :create, :update]
    resources :delayed_jobs, :only => [:index, :show, :update, :destroy], :path => "djs"
  end

  # =======
  # = API =
  # =======

  namespace "api" do
  end

end
