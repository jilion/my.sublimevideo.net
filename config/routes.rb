class NoSubdomain
  def self.matches?(request)
    request.subdomain.blank?
  end
end

MySublimeVideo::Application.routes.draw do

  scope module: 'my' do
    constraints subdomain: 'my' do

      devise_for :users,
                 module: 'my/users',
                 path: '',
                 path_names: { sign_in: 'login', sign_out: 'logout' },
                 skip: [:sessions, :invitations, :registrations] do
        resource :user, only: [], path: '' do
          get    :new,     path: '/signup', as: 'new'
          post   :create,  path: '/signup'

          get    :edit,    path: '/account', as: 'edit'
          put    :update,  path: '/account', as: 'update'
          delete :destroy, path: '/account', as: 'destroy'
        end
        get '/logout' => 'users/sessions#destroy', as: 'destroy_user_session'
      end
      get '/account/edit' => redirect('/account')

      %w[sign_up register].each { |action| get action => redirect { |params, req| "http://#{req.domain}/?p=signup" } }
      %w[login log_in sign_in signin].each    { |action| get action => redirect { |params, req| "http://#{req.domain}/?p=login" } }
      %w[log_out sign_out signout].each { |action| get action => redirect('/logout') }
      get '/invitation/accept' => redirect('/signup?beta=over')
      post '/password/validate' => "users/passwords#validate"

      put '/hide_notice/:id' => 'users#hide_notice'

      scope 'account' do
        resource :billing, only: [:edit, :update]
        resources :applications, controller: 'client_applications', as: :client_applications # don't change this, used by oauth-plugin
      end
      get '/card(/*anything)' => redirect('/account/billing/edit')

      scope "oauth" do
        # OAuth 1 & 2
        get '/authorize' => 'oauth#authorize', as: :oauth_authorize
        delete '/revoke'    => 'oauth#revoke', as: :oauth_revoke

        # OAuth 2
        get '/access_token' => 'oauth#token', as: :oauth_token
      end

      resources :sites, except: [:show] do
        get :state, on: :member

        resource :plan, only: [:edit, :update, :destroy]

        resources :invoices, only: [:index] do
          put :retry, on: :collection
        end

        resources :stats, only: [:index], controller: 'site_stats' do
          put :trial, on: :collection
          get :videos, on: :collection
        end

        resources :video_tags, only: [:show]
      end

      resources :invoices, only: [:show] do
        put :retry_all, on: :collection
      end

      post '/transaction/callback' => 'transactions#callback'

      # DEPRECATED
      get '/refund' => 'refunds#index', as: 'refunds'
      post '/refund' => 'refunds#create', as: 'refund'
      # DEPRECATED

      resource :ticket, only: [:create], path: '/help'
      %w[support feedback].each { |action| get action, to: redirect('/help') }

      # match '/video-tag-builder' => 'video_tag_builder#new', via: :get, as: 'video_tag_builder'
      # match '/video-tag-builder/iframe-embed' => 'video_tag_builder#iframe_embed', via: :get

      get '/r/:type/:token' => 'referrers#redirect', type: /c/, token: /[a-z0-9]{8}/

      post '/pusher/auth' => 'pusher#auth'

      unauthenticated :user do
        root to: redirect { |params, req| "http://#{req.domain}/?p=login" }
      end

      authenticated :user do
        root to: redirect('/sites')
      end

      get '/:page' => 'pages#show', as: :page

    end
  end # my.

  namespace 'api' do
    # Legacy routes
    constraints subdomain: 'my', format: /json|xml/ do

      get 'test_request' => 'apis#test_request'
      resources :sites, only: [:index, :show] do
        member do
          get :usage
        end
      end

    end
  end

  scope module: 'api', as: 'api' do
    constraints subdomain: 'api', format: /json|xml/ do

      match 'test_request' => 'apis#test_request'
      resources :sites, only: [:index, :show] do
        member do
          get :usage
        end
      end

    end
  end # api.

  scope module: 'docs', as: 'docs' do
    constraints subdomain: 'docs' do
      # Deprecated routes
      %w[javascript-api js-api].each { |r| match r => redirect('/javascript-api/usage') }

      resources :releases, only: :index

      get '/*page' => 'pages#show'

      root to: redirect('/quickstart-guide')
    end
  end

  # We put this block out of the following scope to avoid double admin_admin in url helpers...
  devise_for :admins,
             constraints: { subdomain: 'admin' },
             module: 'admin/admins',
             path: '',
             path_names: { sign_in: 'login', sign_out: 'logout' },
             skip: [:registrations] do
    resource :admin_registration, only: [:edit, :update, :destroy], controller: 'admin/admins/registrations', constraints: { subdomain: 'admin' }, path: 'account'
  end

  scope module: 'admin', as: 'admin' do
    constraints subdomain: 'admin' do

      unauthenticated :admin do
        root to: redirect('/login')
      end

      authenticated :admin do
        root to: redirect('/sites'), as: 'admin'
      end

      match '/admin(/*rest)' => redirect { |params, req| "http://admin.#{req.domain}/#{params[:rest]}" }

      %w[log_in sign_in signin].each         { |action| get action => redirect('/login') }
      %w[log_out sign_out signout exit].each { |action| get action => redirect('/logout') }

      resource  :dashboard, only: [:show]

      resources :enthusiasts, only: [:index, :show, :update]

      resources :enthusiast_sites, only: [:update]

      resources :analytics, only: [:index]

      match '/analytics/:report' => 'analytics#show', as: "analytic"

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

      resources :tweets, only: [:index] do
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

  devise_scope :user do
    get '/?p=signup' => 'my/users#new', as: 'signup'
    post '/signup' => 'my/users#create'
    get '/?p=login' => 'my/users/sessions#new', as: 'login'
    post '/login' => 'my/users/sessions#create'
    get '/logout' => 'my/users/sessions#destroy'
  end

  scope module: 'com', as: 'com' do
    constraints(NoSubdomain) do
      # Redirects
      get '/signup' => redirect('/?p=signup')
      get '/login' => redirect('/?p=login')

      # Redirect to subdomains
      match '/docs(/*rest)' => redirect { |params, req| "http://docs.#{req.domain}/#{params[:rest]}" }

      # Docs routes
      %w[javascript-api releases].each do |path|
        match path => redirect { |params, req| "http://docs.#{req.domain}/#{path}" }
      end

      # My routes
      %w[privacy terms sites account].each do |path|
        match path => redirect { |params, req| "http#{Rails.env.production? ? 's' : ''}://my.#{req.domain}/#{path}" }
      end

      match '/notify(/:anything)' => redirect('/')
      match '/enthusiasts(/:anything)' => redirect('/')

      get '/:page' => 'pages#show', as: :page

      get '/r/:type/:token' => 'referrers#redirect', type: /c/, token: /[a-z0-9]{8}/

      root to: 'pages#show', page: 'home'
    end
  end

end
