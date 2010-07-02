namespace :db do
  namespace :update do
    namespace :video_encoding do
      # Done, don't do it again
      # desc "Update old state 'encoding' to new state 'processing', execute this task after having deployed commit 9ebe3defde2897384146821c1ec5e45aaabcc451"
      # task :old_encoding_state_to_new_processing_state => :environment do
      #   VideoEncoding.where(:state => 'encoding').each{ |ve| ve.update_attribute(:state, 'processing') }
      # end
    end
  end
end