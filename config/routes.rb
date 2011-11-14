MySublimeVideo::Application.routes.draw do

  scope module: 'my' do
    constraints subdomain: 'my' do

      devise_for :users,
                 module: 'my/users',
                 path: '',
                 path_names: { sign_in: 'login', sign_out: 'logout' },
                 skip: [:invitations, :registrations] do
        resource :user_registration, only: [], controller: 'users/registrations', path: '' do
          get    :new,     path: '/signup', as: 'new'
          post   :create,  path: '/signup'

          get    :edit,    path: '/account', as: 'edit'
          put    :update,  path: '/account/credentials'
          delete :destroy, path: '/account'
        end
      end
      match '/account/edit' => redirect('/account'), via: :get

      %w[sign_up register].each         { |action| match action => redirect('/signup'), via: :get }
      %w[log_in sign_in signin].each    { |action| match action => redirect('/login'),  via: :get }
      %w[log_out sign_out signout].each { |action| match action => redirect('/logout'), via: :get }
      match '/invitation/accept' => redirect('/signup?beta=over'), via: :get
      match '/password/validate' => "users/passwords#validate", via: :post

      resource :users, only: [:update], path: '/account/info'
      match '/hide_notice/:id' => "users#hide_notice", via: :put

      resources :sites, except: [:show] do
        get :state, on: :member

        resource :plan, only: [:edit, :update, :destroy]

        resources :invoices, only: [:index] do
          put :retry, on: :collection
        end

        resources :stats, only: [:index], controller: 'site_stats' do
          put :trial, on: :collection
        end
      end

      scope 'account' do
        resource :billing, only: [:edit, :update]
      end
      match '/card' => redirect('/account/billing/edit'), via: :get

      resources :invoices, only: [:show] do
        put :retry_all, on: :collection
      end

      match '/transaction/callback' => "transactions#callback", via: :post

      match '/refund' => "refunds#index",  via: :get,  as: 'refunds'
      match '/refund' => "refunds#create", via: :post, as: 'refund'

      resource :ticket, only: [:new, :create], path: '/support', path_names: { new:  '' }
      %w[help feedback].each { |action| match action => redirect('/support'), via: :get }

      match '/video-tag-builder',              to: 'video_tag_builder#new',          via: :get, as: 'video_tag_builder'
      match '/video-tag-builder/iframe-embed', to: 'video_tag_builder#iframe_embed', via: :get

      match ':page', to: 'pages#show', via: :get, as: :my_page, page: /terms|privacy|suspended/
      match 'r/:type/:token', to: 'referrers#redirect', via: :get, type: /c/, token: /[a-z0-9]{8}/

      unauthenticated do
        root to: redirect('/login')
      end

      authenticated :user do
        root to: redirect('/sites')
      end

      match '/pusher/auth' => "pusher#auth", via: :post

      # =======
      # = API =
      # =======

      scope "oauth" do
        # OAuth 2
        match 'access_token' => 'oauth#token', as: :oauth_token

        # OAuth 1 & 2
        match 'authorize' => 'oauth#authorize', as: :oauth_authorize
        match 'revoke'    => 'oauth#revoke',    as: :oauth_revoke, via: :delete
      end

      scope "account" do
        resources :applications, controller: 'client_applications', as: :client_applications # don't change this, used by oauth-plugin
      end

      namespace "api" do
        constraints format: /json|xml/ do
          match 'test_request' => 'api#test_request'
          resources :sites do
            member do
              get :usage
            end
          end
        end
      end

    end
  end # my.

  scope module: 'api' do
    constraints subdomain: 'api', format: /json|xml/ do

      match 'test_request' => 'api#test_request'
      resources :sites do
        member do
          get :usage
        end
      end

    end
  end # api.

  scope module: 'admin' do
    constraints subdomain: 'admin' do

      unauthenticated :admin do
        root to: redirect('/login')
      end

      authenticated :admin do
        root to: redirect('/sites'), as: 'admin'
      end

      devise_for :admins,
                 module: 'admin/admins',
                 path: '',
                 path_names: { sign_in: 'login', sign_out: 'logout' },
                 skip: [:registrations] do
        resource :registrations, only: [:edit, :update, :destroy], path: 'account', controller: 'admins/registrations'
      end
      %w[log_in sign_in signin].each         { |action| match action => redirect('/admin/login'),  via: :get }
      %w[log_out sign_out signout exit].each { |action| match action => redirect('/admin/logout'), via: :get }

      resource  :dashboard, only: [:show]

      resources :enthusiasts, only: [:index, :show, :update]

      resources :enthusiast_sites, only: [:update]

      resources :analytics, only: [:index]

      match 'analytics/:report', to: 'analytics#show', as: "analytic"

      resources :users, only: [:index, :show] do
        member do
          get :become
        end
      end

      resources :sites, only: [:index, :show, :edit, :update] do
        member do
          put :sponsor
        end
      end

      resources :invoices,  only: [:index, :show, :edit] do
        member do
          put :retry_charging
        end
        collection do
          get :monthly
        end
      end

      resources :referrers, only: [:index]

      resources :plans,  only: [:index, :new, :create]

      resources :admins, only: [:index, :destroy]

      resources :mails,  only: [:index, :new, :create]
      scope 'mails' do
        resources :mail_templates, only: [:new, :create, :edit, :update], path: "templates"
        resources :mail_logs,      only: [:show],                         path: "logs"
      end

      resources :releases, only: [:index, :create, :update]

      resources :tweets,   only: [:index] do
        member do
          put :favorite
        end
      end

      resources :delayed_jobs, only: [:index, :show, :update, :destroy], path: "djs"

    end
  end # admin.

  if %w[development test].include? Rails.env
    mount Jasminerice::Engine => "/jasmine"
  end

  # SVS routes
  # match "/signup" => redirect("https://my.sublimevideo.net/signup")
  # match "/register" => redirect("https://my.sublimevideo.net/signup")
  # match "/login" => redirect("https://my.sublimevideo.net/login")
  match "/releases" => redirect("http://docs.sublimevideo.net/releases")
  match "/privacy"  => redirect("/")
  match "/notify(/:anything)"  => redirect("/")
  match "/enthusiasts(/:anything)"  => redirect("/")

  root to: 'pages#show', page: 'home'

  match ':page', to: 'pages#show', via: :get, as: :page, page: /demo|plans|features/

end
