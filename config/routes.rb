class MyPages
  def self.matches?(request)
    pages = Dir.glob('app/views/pages/*.html.haml').map { |p| p.match(%r(app/views/pages/(.*)\.html\.haml))[1] }
    pages.include?(request.params["page"])
  end
end

def https_if_prod_or_staging
  Rails.env.production? || Rails.env.staging? ? 'https' : 'http'
end

MySublimeVideo::Application.routes.draw do

  if %w[development test].include? Rails.env
    mount Jasminerice::Engine => "/jasmine"
  end

  # Redirect to subdomains
  match '/docs(/*rest)' => redirect { |params, req| "http://docs.#{req.domain}/#{params[:rest]}" }
  match '/admin(/*rest)' => redirect { |params, req| "#{https_if_prod_or_staging}://admin.#{req.domain}/#{params[:rest]}" }

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

  # We put this block out of the following scope to avoid double admin_admin in url helpers...
  devise_for :admins, constraints: { subdomain: 'admin' }, module: 'admin/admins', path: '', path_names: { sign_in: 'login', sign_out: 'logout' }, skip: [:registrations]
  devise_scope :admin do
    resource :admin_registration, only: [:edit, :update, :destroy], controller: 'admin/admins/registrations', constraints: { subdomain: 'admin' }, path: 'account'
  end

  scope module: 'admin', as: 'admin' do
    constraints subdomain: 'admin' do
      %w[log_in sign_in signin].each         { |action| get action => redirect('/login') }
      %w[log_out sign_out signout exit].each { |action| get action => redirect('/logout') }

      unauthenticated :admin do
        root to: redirect('/login')
      end

      authenticated :admin do
        root to: redirect('/sites'), as: 'admin'
      end

      resources :sites, only: [:index, :show, :edit, :update] do
        collection do
          get :autocomplete_tag_list
        end
        member do
          put :sponsor
        end
      end
      resources :plans,  only: [:index, :new, :create]
      resources :referrers, only: [:index]

      resources :users, only: [:index, :show, :edit, :update] do
        collection do
          get :autocomplete_tag_list
        end
        member do
          get :become
          get :new_support_request
        end
      end
      resources :enthusiasts, only: [:index, :show]
      resources :enthusiast_sites, only: []
      resources :admins, only: [:index, :edit, :update, :destroy]

      resources :invoices,  only: [:index, :show, :edit] do
        collection do
          get :monthly
        end
        member do
          put :retry_charging
        end
      end

      resources :stats, only: [:index] do
        collection do
          get '/single/:page' => 'stats#show', as: 'single'
          get :more
          get :sales
          get :users
          get :sites
          get :site_stats
          get :site_usages
          get :tweets
        end
      end
      resources :tweets, only: [:index] do
        member do
          put :favorite
        end
      end

      resources :delayed_jobs, only: [:index, :show, :update, :destroy], path: 'djs'
      resources :deals, only: [:index]
      resources :deal_activations, only: [:index], path: 'deals/activations'
      resources :mails,  only: [:index, :new, :create]
      scope 'mails' do
        resources :mail_templates, only: [:new, :create, :edit, :update], path: 'templates'
        resources :mail_logs,      only: [:show],                         path: 'logs'
      end

      resources :releases, only: [:index, :create, :update]
    end
  end # admin.

  constraints subdomain: 'my' do
    devise_for :users, module: 'users', path: '', path_names: { sign_in: 'login', sign_out: 'logout' }, skip: [:registrations]
    devise_scope :user do
      resource :user, only: [], path: '' do
        get    :new,     path: '/signup', as: 'signup'
        post   :create,  path: '/signup'

        get    :edit,    path: '/account', as: 'edit'
        put    :update,  path: '/account', as: 'update'
        delete :destroy, path: '/account', as: 'destroy'
      end
      get  '/login'    => 'users/sessions#new', as: 'login_user'

      get  '/gs-login' => 'users/sessions#new_gs'
      post '/gs-login' => 'users/sessions#create_gs', as: 'gs_login'

      get  '/account/more-info'  => "users#more_info", as: 'more_user_info'

      delete '/notice/:id' => 'users#hide_notice'

      post '/password/validate' => "users/passwords#validate"
    end
    get '/account/edit' => redirect('/account')

    %w[sign_up register].each         { |action| get action => redirect('/signup') }
    %w[log_in sign_in signin].each    { |action| get action => redirect('/login') }
    %w[log_out sign_out signout].each { |action| get action => redirect('/logout') }

    scope 'account' do
      resource :billing, only: [:edit, :update]
      resources :applications, controller: 'client_applications', as: :client_applications # don't change this, used by oauth-plugin
    end
    get '/card(/*anything)' => redirect('/account/billing/edit')

    scope 'oauth' do
      # OAuth 1 & 2
      match '/authorize' => 'oauth#authorize', as: :oauth_authorize, via: [:get, :post]
      delete '/revoke' => 'oauth#revoke', as: :oauth_revoke

      # OAuth 2
      post '/access_token' => 'oauth#token', as: :oauth_token
    end

    resources :sites, except: [:show] do
      resource :plan, only: [:edit, :update, :destroy]

      resources :invoices, only: [:index] do
        put :retry, on: :collection
      end

      resources :stats, only: [:index], controller: 'site_stats' do
        get :videos, on: :collection
      end

      resources :video_tags, only: [:show]
    end
    # for backbone
    get '/sites/stats(/:token)' => 'site_stats#index', as: 'site_stats', format: false

    resources :invoices, only: [:show] do
      put :retry_all, on: :collection
    end

    post '/transaction/callback' => 'transactions#callback'

    resources :deals, only: [:show], path: 'd'

    resource :support_request, only: [:create], path: 'help'
    %w[support feedback].each { |action| get action, to: redirect('/help') }

    resource :video_code, only: [], path: 'video-code-generator' do
      collection do
        get :new, path: '/'
        get :iframe_embed, path: 'iframe-embed'
        post :mime_type_check, path: 'mime-type-check'
      end
    end

    post '/pusher/auth' => 'pusher#auth'
    post '/pusher/webhook' => 'pusher#webhook'

    get '/:page' => 'pages#show', as: :page, constraints: MyPages, format: false

    root to: redirect('/sites')
  end

  # Default url for specs, not reachable by the app because of the my subdomain
  get '/' => "sites#index"

end
