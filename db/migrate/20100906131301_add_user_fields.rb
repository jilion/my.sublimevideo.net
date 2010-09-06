class AddUserFields < ActiveRecord::Migration
  def self.up
    remove_column :users, :full_name
    
    add_column :users, :enthusiast_id, :integer
    add_column :users, :first_name,    :string
    add_column :users, :last_name,     :string
    add_column :users, :postal_code,   :string
    add_column :users, :country,       :string # ISO3166 alpha2
    
    add_column :users, :use_personal, :boolean
    add_column :users, :use_company,  :boolean
    add_column :users, :use_clients,  :boolean
    
    add_column :users, :company_name,          :string
    add_column :users, :company_url,           :string
    add_column :users, :company_job_title,     :string
    add_column :users, :company_employees,     :string
    add_column :users, :company_videos_served, :string
  end
  
  def self.down
    add_column :users, :full_name, :string
    
    remove_column :users, :enthusiast_id
    remove_column :users, :first_name
    remove_column :users, :last_name
    remove_column :users, :postal_code
    remove_column :users, :country
    
    remove_column :users, :use_personal
    remove_column :users, :use_company
    remove_column :users, :use_clients
    
    remove_column :users, :company_name
    remove_column :users, :company_url
    remove_column :users, :company_job_title
    remove_column :users, :company_employees
    remove_column :users, :company_videos_served
  end
end
