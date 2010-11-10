MySublimeVideo::Application.routes.draw do
  
  devise_for :users,
  :path => '',
  :path_names => { :sign_in => 'login', :sign_out => 'logout' },
  :controllers => { :sessions => "users/sessions" },
  :skip => [:invitations, :registrations] do
    resource :user_registration, :only => [], :controller => 'devise/registrations', :path => '' do
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
  resources :sites do
    member do
      get :state
      get :usage
    end
    # resource :addons, :only => [:edit, :update], :controller => 'sites/addons'
  end
  resource :card, :controller => 'credit_cards', :as => :credit_card, :only => [:edit, :update]
  
  match ':page', :to => 'pages#show', :via => :get, :as => :page, :page => /terms|privacy|suspended/
  
  resource :ticket, :only => [:new, :create], :path => '/feedback', :path_names => { :new =>  ''}
  
  root :to => redirect("/sites")
  
  # =========
  # = Admin =
  # =========
  
  match 'admin', :to => redirect('/admin/users'), :as => 'admin'
  
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
    scope "mails" do
      resources :mail_templates, :only => [:new, :create, :edit, :update], :path => "templates"
      resources :mail_logs,      :only => [:show]                        , :path => "logs"
    end
    resources :delayed_jobs, :only => [:index, :show, :update, :destroy], :path => "djs"
    resources :releases, :only => [:index, :create, :update]
    resources :referrers, :only => :index
    resources :stats, :only => :index
  end
  
  # =======
  # = API =
  # =======
  
  namespace "api" do
  end
  
end
#== Route Map
# Generated on 29 Sep 2010 17:07
#
#              protection POST   /protection(.:format)                  {:action=>"create", :controller=>"protections"}
#              protection GET    /protection(.:format)                  {:action=>"show", :controller=>"protections"}
#  accept_user_invitation GET    /invitation/accept(.:format)           {:action=>"edit", :controller=>"devise/invitations"}
#         user_invitation PUT    /invitation/accept(.:format)           {:action=>"update", :controller=>"devise/invitations"}
#   new_user_registration GET    /register(.:format)                    {:action=>"new", :controller=>"users/registrations"}
#       user_registration POST   /register(.:format)                    {:action=>"create", :controller=>"users/registrations"}
#  edit_user_registration GET    /account/edit(.:format)                {:action=>"edit", :controller=>"users/registrations"}
#       user_registration PUT    /account/credentials(.:format)         {:action=>"update", :controller=>"users/registrations"}
#       user_registration DELETE /account(.:format)                     {:action=>"destroy", :controller=>"users/registrations"}
#                 sign_up GET    /sign_up(.:format)                     {:action=>"sign_up"}
#                  signup GET    /signup(.:format)                      {:action=>"signup"}
#                  log_in GET    /log_in(.:format)                      {:action=>"log_in"}
#                 sign_in GET    /sign_in(.:format)                     {:action=>"sign_in"}
#                  signin GET    /signin(.:format)                      {:action=>"signin"}
#                 log_out GET    /log_out(.:format)                     {:action=>"log_out"}
#                sign_out GET    /sign_out(.:format)                    {:action=>"sign_out"}
#                 signout GET    /signout(.:format)                     {:action=>"signout"}
#                    exit GET    /exit(.:format)                        {:action=>"exit"}
#        new_user_session GET    /login(.:format)                       {:action=>"new", :controller=>"users/sessions"}
#            user_session POST   /login(.:format)                       {:action=>"create", :controller=>"users/sessions"}
#    destroy_user_session GET    /logout(.:format)                      {:action=>"destroy", :controller=>"users/sessions"}
#           user_password POST   /password(.:format)                    {:action=>"create", :controller=>"devise/passwords"}
#       new_user_password GET    /password/new(.:format)                {:action=>"new", :controller=>"devise/passwords"}
#      edit_user_password GET    /password/edit(.:format)               {:action=>"edit", :controller=>"devise/passwords"}
#           user_password PUT    /password(.:format)                    {:action=>"update", :controller=>"devise/passwords"}
#       user_confirmation POST   /confirmation(.:format)                {:action=>"create", :controller=>"devise/confirmations"}
#   new_user_confirmation GET    /confirmation/new(.:format)            {:action=>"new", :controller=>"devise/confirmations"}
#       user_confirmation GET    /confirmation(.:format)                {:action=>"show", :controller=>"devise/confirmations"}
#                   users PUT    /account/info(.:format)                {:action=>"update", :controller=>"users"}
#              state_site GET    /sites/:id/state(.:format)             {:action=>"state", :controller=>"sites"}
#                   sites GET    /sites(.:format)                       {:action=>"index", :controller=>"sites"}
#                   sites POST   /sites(.:format)                       {:action=>"create", :controller=>"sites"}
#                new_site GET    /sites/new(.:format)                   {:action=>"new", :controller=>"sites"}
#               edit_site GET    /sites/:id/edit(.:format)              {:action=>"edit", :controller=>"sites"}
#                    site GET    /sites/:id(.:format)                   {:action=>"show", :controller=>"sites"}
#                    site PUT    /sites/:id(.:format)                   {:action=>"update", :controller=>"sites"}
#                    site DELETE /sites/:id(.:format)                   {:action=>"destroy", :controller=>"sites"}
#        edit_credit_card GET    /card/edit(.:format)                   {:action=>"edit", :controller=>"credit_cards"}
#             credit_card PUT    /card(.:format)                        {:action=>"update", :controller=>"credit_cards"}
#                    page GET    /:page(.:format)                       {:page=>/terms|privacy/, :controller=>"pages", :action=>"show"}
#                  ticket POST   /feedback(.:format)                    {:action=>"create", :controller=>"tickets"}
#              new_ticket GET    /feedback(.:format)                    {:action=>"new", :controller=>"tickets"}
#                    root        /(.:format)                            {:to=>#<Proc:0x00000103425938@/Users/Thibaud/.rvm/gems/ruby-1.9.2-p0/gems/actionpack-3.0.0/lib/action_dispatch/routing/mapper.rb:284 (lambda)>}
#                   admin        /admin(.:format)                       {:action=>"admin", :to=>#<Proc:0x0000010340a1b0@/Users/Thibaud/.rvm/gems/ruby-1.9.2-p0/gems/actionpack-3.0.0/lib/action_dispatch/routing/mapper.rb:284 (lambda)>}
#     new_user_invitation GET    /admin/users/invitation/new(.:format)  {:action=>"new", :controller=>"admin/users/invitations"}
#         user_invitation POST   /admin/users/invitation(.:format)      {:action=>"create", :controller=>"admin/users/invitations"}
#    new_admin_invitation GET    /admin/admins/invitation/new(.:format) {:action=>"new", :controller=>"admin/admins/invitations"}
#        admin_invitation POST   /admin/admins/invitation(.:format)     {:action=>"create", :controller=>"admin/admins/invitations"}
# accept_admin_invitation GET    /admin/invitation/accept(.:format)     {:action=>"edit", :controller=>"admin/admins/invitations"}
#        admin_invitation PUT    /admin/invitation(.:format)            {:action=>"update", :controller=>"admin/admins/invitations"}
# edit_admin_registration GET    /admin/account/edit(.:format)          {:action=>"edit", :controller=>"admin/admins/registrations"}
#      admin_registration PUT    /admin/account(.:format)               {:action=>"update", :controller=>"admin/admins/registrations"}
#      admin_registration DELETE /admin/account(.:format)               {:action=>"destroy", :controller=>"admin/admins/registrations"}
#            admin_log_in GET    /admin/log_in(.:format)                
#           admin_sign_in GET    /admin/sign_in(.:format)               
#            admin_signin GET    /admin/signin(.:format)                
#           admin_log_out GET    /admin/log_out(.:format)               
#          admin_sign_out GET    /admin/sign_out(.:format)              
#           admin_signout GET    /admin/signout(.:format)               
#              admin_exit GET    /admin/exit(.:format)                  
#       new_admin_session GET    /admin/login(.:format)                 {:action=>"new", :controller=>"admin/admins/sessions"}
#           admin_session POST   /admin/login(.:format)                 {:action=>"create", :controller=>"admin/admins/sessions"}
#   destroy_admin_session GET    /admin/logout(.:format)                {:action=>"destroy", :controller=>"admin/admins/sessions"}
#          admin_password POST   /admin/password(.:format)              {:action=>"create", :controller=>"admin/admins/passwords"}
#      new_admin_password GET    /admin/password/new(.:format)          {:action=>"new", :controller=>"admin/admins/passwords"}
#     edit_admin_password GET    /admin/password/edit(.:format)         {:action=>"edit", :controller=>"admin/admins/passwords"}
#          admin_password PUT    /admin/password(.:format)              {:action=>"update", :controller=>"admin/admins/passwords"}
#             admin_users GET    /admin/users(.:format)                 {:action=>"index", :controller=>"admin/users"}
#              admin_user GET    /admin/users/:id(.:format)             {:action=>"show", :controller=>"admin/users"}
#            admin_admins GET    /admin/admins(.:format)                {:action=>"index", :controller=>"admin/admins"}
#             admin_admin DELETE /admin/admins/:id(.:format)            {:action=>"destroy", :controller=>"admin/admins"}
#             admin_sites GET    /admin/sites(.:format)                 {:action=>"index", :controller=>"admin/sites"}
#         edit_admin_site GET    /admin/sites/:id/edit(.:format)        {:action=>"edit", :controller=>"admin/sites"}
#              admin_site PUT    /admin/sites/:id(.:format)             {:action=>"update", :controller=>"admin/sites"}
#      admin_delayed_jobs GET    /admin/djs(.:format)                   {:action=>"index", :controller=>"admin/delayed_jobs"}
#       admin_delayed_job GET    /admin/djs/:id(.:format)               {:action=>"show", :controller=>"admin/delayed_jobs"}
#       admin_delayed_job PUT    /admin/djs/:id(.:format)               {:action=>"update", :controller=>"admin/delayed_jobs"}
#       admin_delayed_job DELETE /admin/djs/:id(.:format)               {:action=>"destroy", :controller=>"admin/delayed_jobs"}
#          admin_releases GET    /admin/releases(.:format)              {:action=>"index", :controller=>"admin/releases"}
#          admin_releases POST   /admin/releases(.:format)              {:action=>"create", :controller=>"admin/releases"}
#           admin_release PUT    /admin/releases/:id(.:format)          {:action=>"update", :controller=>"admin/releases"}
#         admin_referrers GET    /admin/referrers(.:format)             {:action=>"index", :controller=>"admin/referrers"}
#         api_invitations POST   /api/invitations(.:format)             {:action=>"create", :controller=>"api/invitations"}
#                  jammit        /assets/:package.:extension(.:format)  {:controller=>"jammit", :action=>"package"}
