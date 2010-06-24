require 'spec_helper'

describe VideosController do
  
  it { should route(:get,    "videos").to(:action => :index) }
  it { should route(:get,    "videos/1").to(:action => :show, :id => "1") }
  it { should route(:get,    "videos/1/edit").to(:action => :edit, :id => "1") }
  it { should route(:post,   "videos").to(:action => :create) }
  it { should route(:put,    "videos/1").to(:action => :update, :id => "1") }
  it { should route(:delete, "videos/1").to(:action => :destroy, :id => "1") }
  it { should route(:get,    "videos/1/transcoded").to(:action => :transcoded, :id => "1") }
  
end