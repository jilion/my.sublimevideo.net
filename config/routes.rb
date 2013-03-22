class SubdomainConstraint
  def initialize(subdomain, options = {})
    @subdomain = subdomain
    @options   = options
  end

  def matches?(request)
    success = (request.subdomains.first == @subdomain)
    success &= (@options[:format] =~ request.format) if @options[:format]
    success
  end
end

class PageExistsConstraint
  def matches?(request)
    Dir.glob("app/views/pages/#{request.params['page']}.html.haml").any?
  end
end

def https_if_prod_or_staging
  Rails.env.production? || Rails.env.staging? ? 'https' : 'http'
end

MySublimeVideo::Application.routes.draw do

  # if Rails.env.development?
  #   require 'i18n/extra_translations'
  #   mount I18n::ExtraTranslations::Server.new => '/i18n'
  # end

  # Redirect to subdomains
  match '/docs(/*rest)' => redirect { |params, req| "http://docs.#{req.domain}/#{params[:rest]}" }

  namespace :private_api do
    resources :sites, only: [:index, :show]
  end

  namespace :api do
    # Legacy routes
    constraints SubdomainConstraint.new('my') do

      get 'test_request' => 'apis#test_request'
      resources :sites, only: [:index, :show] do
        member do
          get :usage
        end
      end

    end
  end

  scope module: 'api', as: 'api' do
    constraints SubdomainConstraint.new('api') do

      get 'test_request' => 'apis#test_request'
      resources :sites, only: [:index, :show] do
        member do
          get :usage
        end
      end

    end
  end # api.

  constraints SubdomainConstraint.new('admin') do
    # We put this block out of the following scope to avoid double admin_admin in url helpers...
    devise_for :admins, module: 'admin/admins', path: '', path_names: { sign_in: 'login', sign_out: 'logout' }, skip: [:registrations]
    devise_scope :admin do
      resource :admin_registration, only: [:edit, :update, :destroy], controller: 'admin/admins/registrations', path: 'account'
    end
  end

  scope module: 'admin', as: 'admin' do
    constraints SubdomainConstraint.new('admin') do
      %w[log_in sign_in signin].each         { |action| get action => redirect('/login') }
      %w[log_out sign_out signout exit].each { |action| get action => redirect('/logout') }

      unauthenticated :admin do
        root to: redirect('/login')
      end

      authenticated :admin do
        root to: redirect('/sites'), as: 'admin'
      end

      resources :sites, only: [:index, :show, :edit, :update] do
        member do
          get :stats
          get :videos_infos
          get :invoices
          get :active_pages
          put :update_app_design_subscription
          put :update_addon_plan_subscription
        end
      end
      resources :plans, only: [:index]
      resources :referrers, only: [:index] do
        collection do
          get :pages
        end
      end

      resources :users, only: [:index, :show, :edit, :update, :destroy] do
        member do
          get :become
          get :stats
          get :invoices
          get :support_requests
          get :new_support_request
          delete :oauth_revoke
        end
      end
      resources :enthusiasts, only: [:index, :show]
      resources :enthusiast_sites, only: []
      resources :admins, only: [:index, :edit, :update, :destroy] do
        member do
          put :reset_auth_token
        end
      end
      resources :feedbacks, only: [:index]
      resources :tailor_made_player_requests, only: [:index, :show, :destroy]

      resources :invoices,  only: [:index, :show, :edit] do
        collection do
          get :monthly
        end
        member do
          put :retry_charging
        end
      end

      get 'stats/single/:page' => 'stats#show', as: 'single_stat'

      resources :trends, only: [:index] do
        collection do
          get :more
          get :billings
          get :revenues
          get :billable_items
          get :users
          get :sites
          get :site_stats
          get :site_usages
          get :tweets
          get :tailor_made_player_requests
        end
      end
      resources :tweets, only: [:index] do
        member do
          put :favorite
        end
      end

      resources :deals, only: [:index]
      resources :deal_activations, only: [:index], path: 'deals/activations'
      resources :mails, only: [:index, :new, :create] do
        collection do
          post :confirm
        end
      end
      scope 'mails' do
        resources :mail_templates, only: [:new, :create, :edit, :update], path: 'templates' do
          member do
            get :preview
          end
        end
        resources :mail_logs,      only: [:show],                         path: 'logs'
      end

      get '/app' => redirect("/app/components/#{App::Component::APP_TOKEN}"), as: 'app'
      namespace :app do
        resources :components, only: [:index, :create, :show, :update, :destroy] do
          resources :component_versions, only: [:index, :create, :show, :destroy], path: 'versions', as: 'versions'
        end
      end
    end
  end # admin.

  constraints SubdomainConstraint.new('my') do
    devise_for :users, module: 'users', path: '', path_names: { sign_in: 'login', sign_out: 'logout' }, skip: [:registrations]
    devise_scope :user do
      resource :user, only: [], path: '' do
        get    :new,     path: '/signup', as: 'signup'
        post   :create,  path: '/signup'

        get    :edit,    path: '/account', as: 'edit'
        put    :update,  path: '/account', as: 'update'
      end
      get  '/login'    => 'users/sessions#new', as: 'login_user'

      get  '/gs-login' => 'users/sessions#new_gs'
      post '/gs-login' => 'users/sessions#create_gs', as: 'gs_login'

      get '/account/more-info' => "users#more_info", as: 'more_user_info'

      get  '/account/cancel' => "users/cancellations#new", as: 'account_cancellation'
      post '/account/cancel' => "users/cancellations#create"

      delete '/notice/:id' => 'users#hide_notice'

      post '/password/validate' => "users/passwords#validate"
    end
    get '/account/edit' => redirect('/account')

    %w[sign_up register].each         { |action| get action => redirect('/signup') }
    %w[log_in sign_in signin].each    { |action| get action => redirect('/login') }
    %w[log_out sign_out signout].each { |action| get action => redirect('/logout') }

    scope 'account' do
      resource :billing, only: [:edit, :update]
      resources :applications, controller: 'client_applications', as: 'client_applications' # don't change this, used by oauth-plugin
    end
    get '/card(/*anything)' => redirect('/account/billing/edit')

    get '/newsletter/subscribe' => 'newsletter#subscribe', as: 'newsletter_subscribe'

    scope 'oauth' do
      # OAuth 1 & 2
      match '/authorize' => 'oauth#authorize', as: :oauth_authorize, via: [:get, :post]
      delete '/revoke' => 'oauth#revoke', as: :oauth_revoke

      # OAuth 2
      post '/access_token' => 'oauth#token', as: :oauth_token
    end

    match '/assistant/new-site' => 'assistant#new_site', as: 'assistant_new_site', via: [:get, :post]
    match '/assistant/:site_id/addons' => 'assistant#addons', as: 'assistant_addons', via: [:get, :put]
    match '/assistant/:site_id/player' => 'assistant#player', as: 'assistant_player', via: [:get, :put]
    get   '/assistant/:site_id/publish-video' => 'assistant#publish_video', as: 'assistant_publish_video'
    match  '/assistant/:site_id/summary' => 'assistant#summary', as: 'assistant_summary', via: [:get, :post]

    get '/addons' => 'addons#directory'

    resources :sites, only: [:index, :edit, :update, :destroy] do
      resources :addons, only: [:index] do
        collection do
          put :update_all
        end
      end

      resources :kits, except: [:destroy], path: 'players' do
        put  :set_as_default, on: :member
        post :process_custom_logo, on: :member
        get :fields, on: :collection
        get :fields, on: :member
      end

      resources :invoices, only: [:index] do
        put :retry, on: :collection
      end

      resources :video_tags, only: [:index], path: 'videos'
      resources :video_tags, only: [:show]

      resource :video_code, only: [], path: 'publish-video' do
        get :new, on: :collection, path: '', as: 'new'
      end
      resources :video_codes, only: [:show], path: 'video-codes'

      resources :stats, only: [:index], controller: 'site_stats' do
        get :videos, on: :collection
      end
    end
    # Legacy redirect
    get  '/video-code-generator' => redirect('/publish-video')
    post '/mime-type-check' => 'video_codes#mime_type_check'
    get  '/sites/new' => redirect('/assistant/new-site')

    get '/publish-video' => 'video_codes#new', as: 'new_video_code'
    get '/stats-demo' => 'site_stats#index', site_id: 'demo'
    get '/stats' => redirect('/stats-demo')
    # old backbone route
    get '/sites/stats/demo' => redirect('/stats-demo')
    get '/sites/stats/:site_id' => redirect { |params, req| "/sites/#{params[:site_id]}/stats" }
    get '/sites/stats' => redirect('/sites')

    resources :stats_exports, only: [:create, :show], path: 'stats/exports'

    resources :invoices, only: [:show] do
      put :retry_all, on: :collection
    end

    post '/transaction/callback' => 'transactions#callback'

    resources :deals, only: [:show], path: 'd'

    get  '/feedback' => "feedbacks#new", as: 'feedback'
    post '/feedback' => "feedbacks#create"

    resource :support_request, only: [:create], path: 'help'
    %w[support].each { |action| get action, to: redirect('/help') }

    post '/pusher/auth' => 'pusher#auth'
    post '/pusher/webhook' => 'pusher#webhook'

    get '/:page' => 'pages#show', as: :page, constraints: PageExistsConstraint.new, format: false

    root to: redirect('/sites')
  end

  # Default url for specs, not reachable by the app because of the my subdomain
  get '/' => "pages#show", page: 'terms' if Rails.env.test?

end
