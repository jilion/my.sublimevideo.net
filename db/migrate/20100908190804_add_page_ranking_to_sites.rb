class AddPageRankingToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :google_rank, :integer
    add_column :sites, :alexa_rank,  :integer
  end
  
  def self.down
    remove_column :sites, :google_rank
    remove_column :sites, :alexa_rank
  end
end
