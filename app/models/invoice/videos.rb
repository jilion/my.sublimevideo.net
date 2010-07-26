class Invoice::Videos < Array
  attr_reader :amount, :traffic_amount, :requests_amount,
              :traffic_upload, :traffic_s3, :traffic_us, :traffic_eu, :traffic_as, :traffic_jp, :traffic_unknown,
              :traffic_upload_amount, :traffic_s3_amount, :traffic_us_amount, :traffic_eu_amount, :traffic_as_amount, :traffic_jp_amount, :traffic_unknown_amount,
              :requests_s3, :requests_us, :requests_eu, :requests_as, :requests_jp, :requests_unknown,
              :requests_s3_amount, :requests_us_amount, :requests_eu_amount, :requests_as_amount, :requests_jp_amount, :requests_unknown_amount,
              :storage_bytehrs, :encoding_time,
              :storage_amount, :encoding_amount,
              :hits # not billed, just for info.
  
  def initialize(invoice, options = {})
    @videos = collect_videos(invoice, options)
    
    calculate_and_set_values
    calculate_and_set_amounts
    
    super(@videos)
  end
  
private
  
  def collect_videos(invoice, options = {})
    videos = invoice.user.videos.includes(:encodings)
    if options[:from_cache]
      videos.collect do |video|
        { 
          :id               => video.id,
          :video_title      => video.title,
          :archived_at      => video.archived_at,
          :traffic_upload   => calculate_upload_traffic(video, invoice),
          :traffic_s3       => video.traffic_s3_cache,
          :traffic_us       => video.traffic_us_cache,
          :traffic_eu       => video.traffic_eu_cache,
          :traffic_as       => video.traffic_as_cache,
          :traffic_jp       => video.traffic_jp_cache,
          :traffic_unknown  => video.traffic_unknown_cache,
          :requests_s3      => video.requests_s3_cache,
          :requests_us      => video.requests_us_cache,
          :requests_eu      => video.requests_eu_cache,
          :requests_as      => video.requests_as_cache,
          :requests_jp      => video.requests_jp_cache,
          :requests_unknown => video.requests_unknown_cache,
          :storage_bytehrs  => calculate_storage_bytes_per_hours(video, invoice),
          :encoding_time    => calculate_encoding_time(video, invoice),
          :hits             => video.hits_cache
        }
      end
    else
      # Warning big requests here if video_usages not compacted
      videos.collect do |video|
        { 
          :id               => video.id,
          :video_title      => video.title,
          :archived_at      => video.archived_at,
          :traffic_upload   => calculate_upload_traffic(video, invoice),
          :traffic_s3       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:traffic_s3),
          :traffic_us       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:traffic_us),
          :traffic_eu       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:traffic_eu),
          :traffic_as       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:traffic_as),
          :traffic_jp       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:traffic_jp),
          :traffic_unknown  => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:traffic_unknown),
          :requests_s3      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_s3),
          :requests_us      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_us),
          :requests_eu      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_eu),
          :requests_as      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_as),
          :requests_jp      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_jp),
          :requests_unknown => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_unknown),
          :storage_bytehrs  => calculate_storage_bytes_per_hours(video, invoice),
          :encoding_time    => calculate_encoding_time(video, invoice),
          :hits             => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:hits)
        }
      end
    end
  end
  
  def calculate_and_set_values
    @traffic_upload  = @videos.sum { |video| video[:traffic_upload].to_i }
    @traffic_s3      = @videos.sum { |video| video[:traffic_s3].to_i }
    @traffic_us      = @videos.sum { |video| video[:traffic_us].to_i }
    @traffic_eu      = @videos.sum { |video| video[:traffic_eu].to_i }
    @traffic_as      = @videos.sum { |video| video[:traffic_as].to_i }
    @traffic_jp      = @videos.sum { |video| video[:traffic_jp].to_i }
    @traffic_unknown = @videos.sum { |video| video[:traffic_unknown].to_i }
    @requests_s3       = @videos.sum { |video| video[:requests_s3].to_i }
    @requests_us       = @videos.sum { |video| video[:requests_us].to_i }
    @requests_eu       = @videos.sum { |video| video[:requests_eu].to_i }
    @requests_as       = @videos.sum { |video| video[:requests_as].to_i }
    @requests_jp       = @videos.sum { |video| video[:requests_jp].to_i }
    @requests_unknown  = @videos.sum { |video| video[:requests_unknown].to_i }
    @storage_bytehrs   = @videos.sum { |video| video[:storage_bytehrs].to_i }
    @encoding_time     = @videos.sum { |video| video[:encoding_time].to_i }
    @hits              = @videos.sum { |video| video[:hits].to_i }
  end
  
  def calculate_and_set_amounts
    @videos.each do |video|
      # TODO, now 100'000 bytes = 1 cent
      video[:traffic_upload_amount]  = video[:traffic_upload].to_i / 100000.0
      video[:traffic_s3_amount]      = video[:traffic_s3].to_i / 100000.0
      video[:traffic_us_amount]      = video[:traffic_us].to_i / 100000.0
      video[:traffic_eu_amount]      = video[:traffic_eu].to_i / 100000.0
      video[:traffic_as_amount]      = video[:traffic_as].to_i / 100000.0
      video[:traffic_jp_amount]      = video[:traffic_jp].to_i / 100000.0
      video[:traffic_unknown_amount] = video[:traffic_unknown].to_i / 100000.0
      # TODO, now 10'000 request = 1 cent
      video[:requests_s3_amount]       = video[:requests_s3].to_i / 10000.0
      video[:requests_us_amount]       = video[:requests_us].to_i / 10000.0
      video[:requests_eu_amount]       = video[:requests_eu].to_i / 10000.0
      video[:requests_as_amount]       = video[:requests_as].to_i / 10000.0
      video[:requests_jp_amount]       = video[:requests_jp].to_i / 10000.0
      video[:requests_unknown_amount]  = video[:requests_unknown].to_i / 10000.0
      # TODO, now 1000'000 bytehrs = 1 cent
      video[:storage_amount]           = video[:storage_bytehrs].to_i / 1000000.0
      # TODO, now 1 second = 1 cent
      video[:encoding_amount]          = video[:encoding_time].to_i
    end
    
    @traffic_upload_amount  = @videos.sum { |video| video[:traffic_upload_amount] }.round
    @traffic_s3_amount      = @videos.sum { |video| video[:traffic_s3_amount] }.round
    @traffic_us_amount      = @videos.sum { |video| video[:traffic_us_amount] }.round
    @traffic_eu_amount      = @videos.sum { |video| video[:traffic_eu_amount] }.round
    @traffic_as_amount      = @videos.sum { |video| video[:traffic_as_amount] }.round
    @traffic_jp_amount      = @videos.sum { |video| video[:traffic_jp_amount] }.round
    @traffic_unknown_amount = @videos.sum { |video| video[:traffic_unknown_amount] }.round
    @traffic_amount         = @traffic_upload_amount + @traffic_s3_amount + @traffic_us_amount + @traffic_eu_amount + @traffic_as_amount + @traffic_jp_amount + @traffic_unknown_amount
    @requests_s3_amount       = @videos.sum { |video| video[:requests_s3_amount] }.round
    @requests_us_amount       = @videos.sum { |video| video[:requests_us_amount] }.round
    @requests_eu_amount       = @videos.sum { |video| video[:requests_eu_amount] }.round
    @requests_as_amount       = @videos.sum { |video| video[:requests_as_amount] }.round
    @requests_jp_amount       = @videos.sum { |video| video[:requests_jp_amount] }.round
    @requests_unknown_amount  = @videos.sum { |video| video[:requests_unknown] }.round
    @requests_amount          = @requests_s3_amount + @requests_us_amount + @requests_eu_amount + @requests_as_amount + @requests_jp_amount + @requests_unknown_amount
    @storage_amount           = @videos.sum { |video| video[:storage_amount] }.round
    @encoding_amount          = @videos.sum { |video| video[:encoding_amount] }.round
    
    @amount = @traffic_amount + @requests_amount + @storage_amount + @encoding_amount
  end
  
  def calculate_upload_traffic(video, invoice)
    invoice.include_date?(video.created_at) ? video.file_size : 0
  end
  
  def calculate_storage_bytes_per_hours(video, invoice)
    bytes_hours = presence_hours(invoice, video.created_at, video.archived_at) * video.file_size.to_i
    bytes_hours += video.encodings.all.sum do |encoding|
      presence_hours(invoice, encoding.file_added_at, encoding.file_removed_at) * encoding.file_size.to_i
    end
    bytes_hours
  end
  
  def presence_hours(invoice, added_at, removed_at)
    if added_at.present?
      if added_at <= invoice.started_on
        if removed_at.nil? || removed_at > invoice.ended_on
          ((invoice.ended_on.to_time - invoice.started_on.to_time) / 60**2).round
        elsif removed_at > invoice.started_on
          ((removed_at - invoice.started_on.to_time) / 60**2).round
        else
          0 # removed_at < invoice.started_on
        end
      elsif added_at < invoice.ended_on
        if removed_at.nil? || removed_at > invoice.ended_on
          ((invoice.ended_on.to_time - added_at) / 60**2).round
        elsif removed_at > invoice.started_on
          ((removed_at - added_at) / 60**2).round
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