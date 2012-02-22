class Version < ActiveRecord::Base
  attr_accessible :admin_id, :ip # for paper_trail, overwritten
end
