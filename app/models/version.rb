class Version < ActiveRecord::Base
  attr_accessible :admin_ip, :ip # for paper_trail, overwritten
end
