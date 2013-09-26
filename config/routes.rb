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
  get '/docs(/*rest)' => redirect { |params, req| "http://docs.#{req.domain}/#{params[:rest]}" }

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
        collection do
          get :paying
        end

        member do
          get :videos_infos
          get :invoices
          get :active_pages
          patch :generate_loader
          patch :generate_settings
          patch :update_design_subscription
          patch :update_addon_plan_subscription
        end
      end
      resources :plans, only: [:index]
      resources :referrers, only: [] do
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
          patch :reset_auth_token
        end
      end
      resources :feedbacks, only: [:index]
      resources :tailor_made_player_requests, only: [:index, :show, :destroy]

      resources :invoices,  only: [:index, :show, :edit] do
        collection do
          get :monthly
          get :yearly
          get :top_customers
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
          patch :favorite
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
        resources :mail_logs, only: [:show], path: 'logs'
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
    namespace :private_api do
      resources :users, only: [:show]
      resources :sites, only: [:index, :show] do
        member do
          put :add_tag
        end

        resources :addons, only: [:index]
        resources :kits, only: [:index]
      end
      resources :oauth2_tokens, only: [:show]
      resources :referrers, only: [:index]
    end

    devise_for :users, module: 'users', controllers: { passwords: 'devise/passwords' }, path: '', path_names: { sign_in: 'login', sign_out: 'logout' }, skip: [:registrations]
    devise_scope :user do
      resource :user, only: [], path: '' do
        get  :new,     path: '/signup', as: 'signup'
        post :create,  path: '/signup'

        get  :edit,    path: '/account', as: 'edit'
        put  :update,  path: '/account', as: 'update'
      end
      get  '/login'    => 'users/sessions#new', as: 'login_user'

      scope 'gs-login' do
        get  '/' => 'users/sessions#new_gs'
        post '/' => 'users/sessions#create_gs', as: 'gs_login'
      end

      scope 'account' do
        get  'more-info' => 'users#more_info', as: 'more_user_info'
        get  'cancel' => 'users/cancellations#new', as: 'account_cancellation'
        post 'cancel' => 'users/cancellations#create'
      end

      delete '/notice/:id' => 'users#hide_notice'
    end

    %w[sign_up register].each         { |action| get action => redirect('/signup') }
    %w[log_in sign_in signin].each    { |action| get action => redirect('/login') }
    %w[log_out sign_out signout].each { |action| get action => redirect('/logout') }

    scope 'account' do
      get 'edit' => redirect('/account')
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

    scope 'assistant' do
      match 'new-site' => 'assistant#new_site', as: 'assistant_new_site', via: [:get, :post]
      match ':site_id/addons' => 'assistant#addons', as: 'assistant_addons', via: [:get, :put, :patch]
      match ':site_id/player' => 'assistant#player', as: 'assistant_player', via: [:get, :put, :patch]
      get   ':site_id/publish-video' => 'assistant#publish_video', as: 'assistant_publish_video'
      match ':site_id/summary' => 'assistant#summary', as: 'assistant_summary', via: [:get, :post]
    end

    resources :addons, only: [:index, :show]

    resources :sites, only: [:index, :edit, :update, :destroy] do
      resources :addons, only: [:index, :show] do
        put :subscribe, on: :collection
      end

      resources :kits, except: [:destroy], path: 'players' do
        member do
          put  :set_as_default
          post :process_custom_logo
          get :fields
        end
        get :fields, on: :collection
      end

      resources :invoices, only: [:index] do
        put :retry, on: :collection
      end

      resources :video_tags, only: [:index], path: 'videos' do
        resources :video_stats, only: [:index], path: 'stats', as: :stats
      end
      resources :video_tags, only: [:show]

      resources :video_codes, only: [:new, :edit], path: 'videos', path_names: { edit: 'code' }

      resources :stats, only: [:index], controller: 'site_stats' do
        get :videos, on: :collection
      end
    end

    # Legacy redirect
    # get  '/video-code-generator' => redirect('/publish-video')
    %w[video-code-generator publish-video].each { |action| get action, to: redirect('/videos/new') }
    get '/sites/:site_id/publish-video' => redirect { |params, req| "/sites/#{params[:site_id]}/videos/new" }
    post '/mime-type-check' => 'video_codes#mime_type_check'
    get  '/sites/new' => redirect('/assistant/new-site')

    get '/videos/new' => 'video_codes#new', as: 'new_video_code'
    get '/stats-demo' => 'site_stats#index', site_id: 'demo'
    get '/stats' => redirect('/stats-demo')

    # old backbone route
    scope 'sites/stats' do
      get '/' => redirect('/sites')
      get 'demo' => redirect('/stats-demo')
      get ':site_id' => redirect { |params, req| "/sites/#{params[:site_id]}/stats" }
    end

    resources :stats_exports, only: [:create, :show], path: 'stats/exports'

    resources :invoices, only: [:show] do
      put :retry_all, on: :collection
    end

    post '/transaction/callback' => 'transactions#callback'

    resources :deals, only: [:show], path: 'd'

    scope 'feedback' do
      get  '/' => 'feedbacks#new', as: 'feedback'
      post '/' => 'feedbacks#create'
    end

    resource :support_request, only: [:create], path: 'help'
    %w[support].each { |action| get action, to: redirect('/help') }

    scope 'pusher' do
      post 'auth' => 'pusher#auth'
      post 'webhook' => 'pusher#webhook'
    end

    get '/:page' => 'pages#show', as: :page, constraints: PageExistsConstraint.new, format: false

    root to: redirect('/sites')
  end

  # Default url for specs, not reachable by the app because of the my subdomain
  get '/' => 'pages#show', page: 'terms' if Rails.env.test?
end
