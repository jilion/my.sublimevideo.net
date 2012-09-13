# encoding: utf-8
require 'abstract_unit'
require 'controller/fake_controllers'
require 'active_support/core_ext/object/with_options'

module ActionPack
  class URLForIntegrationTest < ActiveSupport::TestCase
    include RoutingTestHelpers

    Model = Struct.new(:to_param)

    Mapping = lambda {
      namespace :admin do
        resources :users, :posts
      end

      namespace 'api' do
        root :to => 'users#index'
      end

      match '/blog(/:year(/:month(/:day)))' => 'posts#show_date',
        :constraints => {
          :year => /(19|20)\d\d/,
          :month => /[01]?\d/,
          :day => /[0-3]?\d/
        },
        :day => nil,
        :month => nil

      match 'archive/:year', :controller => 'archive', :action => 'index',
        :defaults => { :year => nil },
        :constraints => { :year => /\d{4}/ },
        :as => "blog"

      resources :people
      #match 'legacy/people' => "people#index", :legacy => "true"

      match 'symbols', :controller => :symbols, :action => :show, :name => :as_symbol
      match 'id_default(/:id)' => "foo#id_default", :id => 1
      match 'get_or_post' => "foo#get_or_post", :via => [:get, :post]
      match 'optional/:optional' => "posts#index"
      match 'projects/:project_id' => "project#index", :as => "project"
      match 'clients' => "projects#index"

      match 'ignorecase/geocode/:postalcode' => 'geocode#show', :postalcode => /hx\d\d-\d[a-z]{2}/i
      match 'extended/geocode/:postalcode' => 'geocode#show',:constraints => {
        :postalcode => /# Postcode format
        \d{5} #Prefix
        (-\d{4})? #Suffix
        /x
      }, :as => "geocode"

      match 'news(.:format)' => "news#index"

      match 'comment/:id(/:action)' => "comments#show"
      match 'ws/:controller(/:action(/:id))', :ws => true
      match 'account(/:action)' => "account#subscription"
      match 'pages/:page_id/:controller(/:action(/:id))'
      match ':controller/ping', :action => 'ping'
      match ':controller(/:action(/:id))(.:format)'
      root :to => "news#index"
    }

    def setup
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw(&Mapping)
    end

    [
      ['/admin/users',[ { :use_route => 'admin_users' }]],
      ['/admin/users',[ { :controller => 'admin/users' }]],
      ['/admin/users',[ { :controller => 'admin/users', :action => 'index' }]],
      ['/admin/users',[ { :action => 'index' }, { :controller => 'admin/users' }]],
      ['/admin/users',[ { :controller => 'users', :action => 'index' }, { :controller => 'admin/accounts' }]],
      ['/people',[      { :controller => '/people', :action => 'index' }, { :controller => 'admin/accounts' }]],

      ['/admin/posts',[     { :controller => 'admin/posts' }]],
      ['/admin/posts/new',[ { :controller => 'admin/posts', :action => 'new' }]],

      ['/blog/2009',[     { :controller => 'posts', :action => 'show_date', :year => 2009 }]],
      ['/blog/2009/1',[   { :controller => 'posts', :action => 'show_date', :year => 2009, :month => 1 }]],
      ['/blog/2009/1/1',[ { :controller => 'posts', :action => 'show_date', :year => 2009, :month => 1, :day => 1 }]],

      ['/archive/2010',[ { :controller => 'archive', :action => 'index', :year => '2010' }]],
      ['/archive',[      { :controller => 'archive', :action => 'index' }]],
      ['/archive?year=january',[ { :controller => 'archive', :action => 'index', :year => 'january' }]],

      ['/people',[ { :controller => 'people', :action => 'index' }]],
      ['/people',[ { :action => 'index' }, { :controller => 'people' }]],
      ['/people',[ { :action => 'index' }, { :controller => 'people', :action => 'show', :id => '1' }]],
      ['/people',[ { :controller => 'people', :action => 'index' }, { :controller => 'people', :action => 'show', :id => '1' }]],
      ['/people',[ {}, { :controller => 'people', :action => 'index' }]],
      ['/people/1',[   { :controller => 'people', :action => 'show' }, { :controller => 'people', :action => 'show', :id => '1' }]],
      ['/people/new',[ { :use_route => 'new_person' }]],
      ['/people/new',[ { :controller => 'people', :action => 'new' }]],
      ['/people/1',[   { :use_route => 'person', :id => '1' }]],
      ['/people/1',[   { :controller => 'people', :action => 'show', :id => '1' }]],
      ['/people/1.xml',[ { :controller => 'people', :action => 'show', :id => '1', :format => 'xml' }]],
      ['/people/1',[ { :controller => 'people', :action => 'show', :id => 1 }]],
      ['/people/1',[ { :controller => 'people', :action => 'show', :id => Model.new('1') }]],
      ['/people/1',[ { :action => 'show', :id => '1' }, { :controller => 'people', :action => 'index' }]],
      ['/people/1',[ { :action => 'show', :id => 1 }, { :controller => 'people', :action => 'show', :id => '1' }]],
      ['/people',[   { :controller => 'people', :action => 'index' }, { :controller => 'people', :action => 'show', :id => '1' }]],
      ['/people/1',[ {}, { :controller => 'people', :action => 'show', :id => '1' }]],
      ['/people/1',[ { :controller => 'people', :action => 'show' }, { :controller => 'people', :action => 'index', :id => '1' }]],
      ['/people/1/edit',[     { :controller => 'people', :action => 'edit', :id => '1' }]],
      ['/people/1/edit.xml',[ { :controller => 'people', :action => 'edit', :id => '1', :format => 'xml' }]],
      ['/people/1/edit',[     { :use_route => 'edit_person', :id => '1' }]],
      ['/people/1?legacy=true',[ { :controller => 'people', :action => 'show', :id => '1', :legacy => 'true' }]],
      ['/people?legacy=true',[   { :controller => 'people', :action => 'index', :legacy => 'true' }]],

      ['/id_default/2',[ { :controller => 'foo', :action => 'id_default', :id => '2' }]],
      ['/id_default',[   { :controller => 'foo', :action => 'id_default', :id => '1' }]],
      ['/id_default',[   { :controller => 'foo', :action => 'id_default', :id => 1 }]],
      ['/id_default',[   { :controller => 'foo', :action => 'id_default' }]],
      ['/optional/bar',[ { :controller => 'posts', :action => 'index', :optional => 'bar' }]],
      ['/posts',[ { :controller => 'posts', :action => 'index' }]],

      ['/project',[    { :controller => 'project', :action => 'index' }]],
      ['/projects/1',[ { :controller => 'project', :action => 'index', :project_id => '1' }]],
      ['/projects/1',[ { :controller => 'project', :action => 'index'}, {:project_id => '1' }]],
      ['/projects/1',[ { :use_route => 'project', :controller => 'project', :action => 'index', :project_id => '1' }]],
      ['/projects/1',[ { :use_route => 'project', :controller => 'project', :action => 'index' }, { :project_id => '1' }]],

      ['/clients',[ { :controller => 'projects', :action => 'index' }]],
      ['/clients?project_id=1',[ { :controller => 'projects', :action => 'index', :project_id => '1' }]],
      ['/clients',[ { :controller => 'projects', :action => 'index' }, { :project_id => '1' }]],
      ['/clients',[ { :action => 'index' }, { :controller => 'projects', :action => 'index', :project_id => '1' }]],

      ['/comment/20',[   { :id => 20 }, { :controller => 'comments', :action => 'show' }]],
      ['/comment/20',[   { :controller => 'comments', :id => 20, :action => 'show' }]],
      ['/comments/boo',[ { :controller => 'comments', :action => 'boo' }]],

      ['/ws/posts/show/1',[ { :controller => 'posts', :action => 'show', :id => '1', :ws => true }]],
      ['/ws/posts',[        { :controller => 'posts', :action => 'index', :ws => true }]],

      ['/account',[         { :controller => 'account', :action => 'subscription' }]],
      ['/account/billing',[ { :controller => 'account', :action => 'billing' }]],

      ['/pages/1/notes/show/1',[ { :page_id => '1', :controller => 'notes', :action => 'show', :id => '1' }]],
      ['/pages/1/notes/list',[   { :page_id => '1', :controller => 'notes', :action => 'list' }]],
      ['/pages/1/notes',[ { :page_id => '1', :controller => 'notes', :action => 'index' }]],
      ['/pages/1/notes',[ { :page_id => '1', :controller => 'notes' }]],
      ['/notes',[         { :page_id => nil, :controller => 'notes' }]],
      ['/notes',[         { :controller => 'notes' }]],
      ['/notes/print',[   { :controller => 'notes', :action => 'print' }]],
      ['/notes/print',[   {}, { :controller => 'notes', :action => 'print' }]],

      ['/notes/index/1',[ { :controller => 'notes' }, { :controller => 'notes', :id => '1' }]],
      ['/notes/index/1',[ { :controller => 'notes' }, { :controller => 'notes', :id => '1', :foo => 'bar' }]],
      ['/notes/index/1',[ { :controller => 'notes' }, { :controller => 'notes', :id => '1' }]],
      ['/notes/index/1',[ { :action => 'index' }, { :controller => 'notes', :id => '1' }]],
      ['/notes/index/1',[ {}, { :controller => 'notes', :id => '1' }]],
      ['/notes/show/1',[  {}, { :controller => 'notes', :action => 'show', :id => '1' }]],
      ['/notes/index/1',[ { :controller => 'notes', :id => '1' }, { :foo => 'bar' }]],
      ['/posts',[      { :controller => 'posts' }, { :controller => 'notes', :action => 'show', :id => '1' }]],
      ['/notes/list',[ { :action => 'list' }, { :controller => 'notes', :action => 'show', :id => '1' }]],

      ['/posts/ping',[    { :controller => 'posts', :action => 'ping' }]],
      ['/posts/show/1',[  { :controller => 'posts', :action => 'show', :id => '1' }]],
      ['/posts',[         { :controller => 'posts' }]],
      ['/posts',[         { :controller => 'posts', :action => 'index' }]],
      ['/posts',[         { :controller => 'posts' }, { :controller => 'posts', :action => 'index' }]],
      ['/posts/create',[  { :action => 'create' }, { :controller => 'posts' }]],
      ['/posts?foo=bar',[ { :controller => 'posts', :foo => 'bar' }]],
      ['/posts?foo%5B%5D=bar&foo%5B%5D=baz', [{ :controller => 'posts', :foo => ['bar', 'baz'] }]],
      ['/posts?page=2',  [{ :controller => 'posts', :page => 2 }]],
      ['/posts?q%5Bfoo%5D%5Ba%5D=b', [{ :controller => 'posts', :q => { :foo => { :a => 'b'}} }]],

      ['/news.rss', [{ :controller => 'news', :action => 'index', :format => 'rss' }]],
    ].each_with_index do |(url, params), i|
    define_method("test_#{url.gsub(/\W/, '_')}_#{i}") do
      assert_equal url, url_for(@routes, *params), params.inspect
    end
    end
  end
end
