class Invoice::Videos < Array
  attr_reader :amount, :bandwidth_amount, :requests_amount, :storage_amount, :encoding_amount,
              :bandwidth_upload, :bandwidth_s3, :bandwidth_us, :bandwidth_eu, :bandwidth_as, :bandwidth_jp, :bandwidth_unknown,
              :requests_s3, :requests_us, :requests_eu, :requests_as, :requests_jp, :requests_unknown,
              :storage_bytehrs, :encoding_time,
              :hits # not billed, just for info.
  
  # bandwidth
    # upload original to panda
  # request
  # storage
    # thumbnail storage
    # DONE - update video.archive_encodings to archive only non-deprecated
    # DONE - update total_size (use non-deprecated encoding size)
    # calculate price from “TimedStorage-ByteHrs”  (using video.archived_at when video is archived)
      # http://aws.amazon.com/s3/faqs/#How_will_I_be_charged_and_billed_for_my_use_of_Amazon_S3
      # deals with encoding time
  # encoding time
    # calulate total for encodings.started_encoding_at within invoice date
  
  def initialize(invoice, options = {})
    @videos = [] # collect_videos(invoice, options)
    # calculate_and_set_hits
    # calculate_and_set_amounts(invoice)
    
    @amount = 0
    
    super(@videos)
  end
  
private
  
  def collect_videos(invoice, options = {})
    if options[:from_cache]
      invoice.user.videos.include(:encodings).collect do |video|
        { 
          :id                => video.id,
          :video_title       => video.title,
          :archived_at       => video.archived_at,
          :bandwidth_upload  => calculate_upload_bandwidth(video, invoice),
          :bandwidth_s3      => video.bandwidth_s3_cache,
          :bandwidth_us      => video.bandwidth_us_cache,
          :bandwidth_eu      => video.bandwidth_eu_cache,
          :bandwidth_as      => video.bandwidth_as_cache,
          :bandwidth_jp      => video.bandwidth_jp_cache,
          :bandwidth_unknown => video.bandwidth_unknown_cache,
          :requests_s3       => video.requests_s3_cache,
          :requests_us       => video.requests_us_cache,
          :requests_eu       => video.requests_eu_cache,
          :requests_as       => video.requests_as_cache,
          :requests_jp       => video.requests_jp_cache,
          :requests_unknown  => video.requests_unknown_cache,
          :storage_bytehrs   => calculate_storage_bytehrs(video, invoice),
          :encoding_time     => calculate_encoding_time(video, invoice),
          :hits              => video.hits_cache
        }
      end
    else
      # invoice.user.sites.collect do |site|
      #   { :id => site.id,
      #     :hostname => site.hostname,
      #     :archived_at => site.archived_at,
      #     # Warning big request here if site_usages not compacted
      #     :loader_hits => site.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:loader_hits),
      #     :player_hits => site.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:player_hits)
      #   }
      # end
    end
  end
  
  def calculate_and_set_hits
    @loader_hits = @sites.sum { |site| site[:loader_hits] }
    @player_hits = @sites.sum { |site| site[:player_hits] }
  end
  
  def calculate_and_set_amounts(invoice)
    if invoice.user.trial_ended_at.nil? || (invoice.user.trial_ended_at > invoice.started_on && invoice.user.trial_ended_at < invoice.ended_on)
      # TODO Rewrite, test if trial_ended_at is inside the invoice interval & calculate how much free hits remaining 
      loader_hits = @loader_hits > User::Trial.free_loader_hits ? @loader_hits - User::Trial.free_loader_hits : 0
      player_hits = @player_hits > User::Trial.free_player_hits ? @player_hits - User::Trial.free_player_hits : 0
    else
      loader_hits = @loader_hits
      player_hits = @player_hits
    end
    
    # TODO, now 1 hit = 1 cent
    @sites.each do |site|
      site[:loader_amount] = site[:loader_hits]
      site[:player_amount] = site[:player_hits]
    end
    @loader_amount = loader_hits
    @player_amount = player_hits
    @amount = @loader_amount + @player_amount
  end
  
  def calculate_upload_bandwidth(video, invoice)
    0
  end
  
  def calculate_storage_bytehrs(video, invoice)
    0
  end
  
  def calculate_encoding_time(video, invoice)
    0
  end
  
end