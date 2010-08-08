class Invoice::Videos < Array
  attr_reader :amount, :traffic_amount, :requests_amount,
              :storage_amount, :encoding_amount,
              :hits # not billed, just for info.
  
  def initialize(invoice, options = {})
    @videos = collect_videos(invoice, options)
    @hits = sum_for(:hits)
    
    calculate_and_set_amounts
    
    super(@videos)
  end
  
private
  
  def collect_videos(invoice, options = {})
    videos = invoice.user.videos.includes(:encodings)
    if options[:from_cache]
      videos.collect do |video|
        { 
          :id                 => video.id,
          :video_title        => video.title,
          :archived_at        => video.archived_at,
          :traffic_upload     => calculate_upload_traffic(video, invoice),
          :traffic_s3         => video.traffic_s3_cache,
          :traffic_us         => video.traffic_us_cache,
          :traffic_eu         => video.traffic_eu_cache,
          :traffic_as         => video.traffic_as_cache,
          :traffic_jp         => video.traffic_jp_cache,
          :traffic_unknown    => video.traffic_unknown_cache,
          :requests_s3        => video.requests_s3_cache,
          :requests_us        => video.requests_us_cache,
          :requests_eu        => video.requests_eu_cache,
          :requests_as        => video.requests_as_cache,
          :requests_jp        => video.requests_jp_cache,
          :requests_unknown   => video.requests_unknown_cache,
          :storage_bytes_hour => calculate_storage_bytes_hour(video, invoice),
          :encoding_time      => calculate_encoding_time(video, invoice),
          :hits               => video.hits_cache
        }
      end
    else
      # Warning big requests here if video_usages not compacted
      videos.collect do |video|
        { 
          :id                 => video.id,
          :video_title        => video.title,
          :archived_at        => video.archived_at,
          :traffic_upload     => calculate_upload_traffic(video, invoice),
          :traffic_s3         => video.usages.between(invoice.started_on, invoice.ended_on).sum(:traffic_s3),
          :traffic_us         => video.usages.between(invoice.started_on, invoice.ended_on).sum(:traffic_us),
          :traffic_eu         => video.usages.between(invoice.started_on, invoice.ended_on).sum(:traffic_eu),
          :traffic_as         => video.usages.between(invoice.started_on, invoice.ended_on).sum(:traffic_as),
          :traffic_jp         => video.usages.between(invoice.started_on, invoice.ended_on).sum(:traffic_jp),
          :traffic_unknown    => video.usages.between(invoice.started_on, invoice.ended_on).sum(:traffic_unknown),
          :requests_s3        => video.usages.between(invoice.started_on, invoice.ended_on).sum(:requests_s3),
          :requests_us        => video.usages.between(invoice.started_on, invoice.ended_on).sum(:requests_us),
          :requests_eu        => video.usages.between(invoice.started_on, invoice.ended_on).sum(:requests_eu),
          :requests_as        => video.usages.between(invoice.started_on, invoice.ended_on).sum(:requests_as),
          :requests_jp        => video.usages.between(invoice.started_on, invoice.ended_on).sum(:requests_jp),
          :requests_unknown   => video.usages.between(invoice.started_on, invoice.ended_on).sum(:requests_unknown),
          :storage_bytes_hour => calculate_storage_bytes_hour(video, invoice),
          :encoding_time      => calculate_encoding_time(video, invoice),
          :hits               => video.usages.between(invoice.started_on, invoice.ended_on).sum(:hits)
        }
      end
    end
  end
  
  def sum_for(field)
    @videos.sum { |video| video.key?(field) ? video[field].to_i : 0 }
  end
  
  def traffic_sum
    %w[upload s3 us eu as jp unknown].sum { |traffic_field| sum_for(:"traffic_#{traffic_field}") }
  end
  
  def requests_sum
    %w[s3 us eu as jp unknown].sum { |requests_field| sum_for(:"requests_#{requests_field}") }
  end
  
  def calculate_and_set_amounts
    @traffic_amount  = (traffic_sum.to_f / 1.gigabyte) * Prices.price_in_cents_for_1GB_traffic
    
    @requests_amount = (requests_sum / 10000) * Prices.price_in_cents_for_10000_requests
    
    @storage_amount  = (sum_for(:storage_bytes_hour).to_f / 1.gigabyte) * Prices.price_in_cents_for_1GB_per_hour
    
    @encoding_amount = sum_for(:encoding_time) * Prices.price_in_cents_for_1s_of_encoding
    
    @amount = [@traffic_amount, @requests_amount, @storage_amount, @encoding_amount].sum.round
  end
  
  def calculate_upload_traffic(video, invoice)
    invoice.include_date?(video.created_at) ? video.file_size : 0
  end
  
  def calculate_storage_bytes_hour(video, invoice)
    bytes_hour = presence_hours(invoice, video.created_at, video.archived_at) * video.file_size.to_i
    bytes_hour += video.encodings.all.sum do |encoding|
      presence_hours(invoice, encoding.file_added_at, encoding.file_removed_at) * encoding.file_size.to_i
    end
    bytes_hour
  end
  
  def presence_hours(invoice, added_at, removed_at)
    if added_at.present?
      if added_at <= invoice.started_on
        if removed_at.nil? || removed_at > invoice.ended_on
          ((invoice.ended_on.to_time - invoice.started_on.to_time) / 1.hour).round
        elsif removed_at > invoice.started_on
          ((removed_at - invoice.started_on.to_time) / 1.hour).round
        else
          0 # removed_at < invoice.started_on
        end
      elsif added_at < invoice.ended_on
        if removed_at.nil? || removed_at > invoice.ended_on
          ((invoice.ended_on.to_time - added_at) / 1.hour).round
        elsif removed_at > invoice.started_on
          ((removed_at - added_at) / 1.hour).round
        else
          0 # removed_at < invoice.started_on
        end
      else
        0
      end
    else
      0
    end
  end
  
  def calculate_encoding_time(video, invoice)
    video.encodings.all.sum do |encoding|
      invoice.include_date?(encoding.started_encoding_at) ? encoding.encoding_time : 0
    end
  end
  
end