class Invoice::Videos < Array
  attr_reader :amount, :bandwidth_amount, :requests_amount,
              :bandwidth_upload, :bandwidth_s3, :bandwidth_us, :bandwidth_eu, :bandwidth_as, :bandwidth_jp, :bandwidth_unknown,
              :bandwidth_upload_amount, :bandwidth_s3_amount, :bandwidth_us_amount, :bandwidth_eu_amount, :bandwidth_as_amount, :bandwidth_jp_amount, :bandwidth_unknown_amount,
              :requests_s3, :requests_us, :requests_eu, :requests_as, :requests_jp, :requests_unknown,
              :requests_s3_amount, :requests_us_amount, :requests_eu_amount, :requests_as_amount, :requests_jp_amount, :requests_unknown_amount,
              :storage_bytehrs, :encoding_time,
              :storage_amount, :encoding_amount,
              :hits # not billed, just for info.
  
  # bandwidth
    # upload original to panda
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
      # Warning big requests here if video_usages not compacted
      videos.collect do |video|
        { 
          :id                => video.id,
          :video_title       => video.title,
          :archived_at       => video.archived_at,
          :bandwidth_upload  => calculate_upload_bandwidth(video, invoice),
          :bandwidth_s3      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:bandwidth_s3),
          :bandwidth_us      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:bandwidth_us),
          :bandwidth_eu      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:bandwidth_eu),
          :bandwidth_as      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:bandwidth_as),
          :bandwidth_jp      => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:bandwidth_jp),
          :bandwidth_unknown => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:bandwidth_unknown),
          :requests_s3       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_s3),
          :requests_us       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_us),
          :requests_eu       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_eu),
          :requests_as       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_as),
          :requests_jp       => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_jp),
          :requests_unknown  => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:requests_unknown),
          :storage_bytehrs   => calculate_storage_bytehrs(video, invoice),
          :encoding_time     => calculate_encoding_time(video, invoice),
          :hits              => video.usages.started_after(invoice.started_on).ended_before(invoice.ended_on).sum(:hits)
        }
      end
    end
  end
  
  def calculate_and_set_values
    @bandwidth_upload  = @videos.sum { |video| video[:bandwidth_upload] }
    @bandwidth_s3      = @videos.sum { |video| video[:bandwidth_s3] }
    @bandwidth_us      = @videos.sum { |video| video[:bandwidth_us] }
    @bandwidth_eu      = @videos.sum { |video| video[:bandwidth_eu] }
    @bandwidth_as      = @videos.sum { |video| video[:bandwidth_as] }
    @bandwidth_jp      = @videos.sum { |video| video[:bandwidth_jp] }
    @bandwidth_unknown = @videos.sum { |video| video[:bandwidth_unknown] }
    @requests_s3       = @videos.sum { |video| video[:requests_s3] }
    @requests_us       = @videos.sum { |video| video[:requests_us] }
    @requests_eu       = @videos.sum { |video| video[:requests_eu] }
    @requests_as       = @videos.sum { |video| video[:requests_as] }
    @requests_jp       = @videos.sum { |video| video[:requests_jp] }
    @requests_unknown  = @videos.sum { |video| video[:requests_unknown] }
    @storage_bytehrs   = @videos.sum { |video| video[:storage_bytehrs] }
    @encoding_time     = @videos.sum { |video| video[:encoding_time] }
    @hits              = @videos.sum { |video| video[:hits] }
  end
  
  def calculate_and_set_amounts
    @videos.each do |video|
      # TODO, now 100'000 bytes = 1 cent
      video[:bandwidth_upload_amount]  = video[:bandwidth_upload] / 100000.0
      video[:bandwidth_s3_amount]      = video[:bandwidth_s3] / 100000.0
      video[:bandwidth_us_amount]      = video[:bandwidth_us] / 100000.0
      video[:bandwidth_eu_amount]      = video[:bandwidth_eu] / 100000.0
      video[:bandwidth_as_amount]      = video[:bandwidth_as] / 100000.0
      video[:bandwidth_jp_amount]      = video[:bandwidth_jp] / 100000.0
      video[:bandwidth_unknown_amount] = video[:bandwidth_unknown] / 100000.0
      # TODO, now 10'000 request = 1 cent
      video[:requests_s3_amount]       = video[:requests_s3] / 10000.0
      video[:requests_us_amount]       = video[:requests_us] / 10000.0
      video[:requests_eu_amount]       = video[:requests_eu] / 10000.0
      video[:requests_as_amount]       = video[:requests_as] / 10000.0
      video[:requests_jp_amount]       = video[:requests_jp] / 10000.0
      video[:requests_unknown_amount]  = video[:requests_unknown] / 10000.0
      # TODO, now 1000'000 bytehrs = 1 cent
      video[:storage_amount]           = video[:storage_bytehrs] / 1000000.0
      # TODO, now 1 second = 1 cent
      video[:encoding_amount]          = video[:encoding_time]
    end
    
    @bandwidth_upload_amount  = @videos.sum { |video| video[:bandwidth_upload_amount] }.round
    @bandwidth_s3_amount      = @videos.sum { |video| video[:bandwidth_s3_amount] }.round
    @bandwidth_us_amount      = @videos.sum { |video| video[:bandwidth_us_amount] }.round
    @bandwidth_eu_amount      = @videos.sum { |video| video[:bandwidth_eu_amount] }.round
    @bandwidth_as_amount      = @videos.sum { |video| video[:bandwidth_as_amount] }.round
    @bandwidth_jp_amount      = @videos.sum { |video| video[:bandwidth_jp_amount] }.round
    @bandwidth_unknown_amount = @videos.sum { |video| video[:bandwidth_unknown_amount] }.round
    @bandwidth_amount         = @bandwidth_upload_amount + @bandwidth_s3_amount + @bandwidth_us_amount + @bandwidth_eu_amount + @bandwidth_as_amount + @bandwidth_jp_amount + @bandwidth_unknown_amount
    @requests_s3_amount       = @videos.sum { |video| video[:requests_s3_amount] }.round
    @requests_us_amount       = @videos.sum { |video| video[:requests_us_amount] }.round
    @requests_eu_amount       = @videos.sum { |video| video[:requests_eu_amount] }.round
    @requests_as_amount       = @videos.sum { |video| video[:requests_as_amount] }.round
    @requests_jp_amount       = @videos.sum { |video| video[:requests_jp_amount] }.round
    @requests_unknown_amount  = @videos.sum { |video| video[:requests_unknown] }.round
    @requests_amount          = @requests_s3_amount + @requests_us_amount + @requests_eu_amount + @requests_as_amount + @requests_jp_amount + @requests_unknown_amount
    @storage_amount           = @videos.sum { |video| video[:storage_amount] }.round
    @encoding_amount          = @videos.sum { |video| video[:encoding_amount] }.round
    
    @amount = @bandwidth_amount + @requests_amount + @storage_amount + @encoding_amount
  end
  
  def calculate_upload_bandwidth(video, invoice)
    invoice.include_date?(video.created_at) ? video.file_size : 0
  end
  
  def calculate_storage_bytehrs(video, invoice)
    bytehrs = presence_hours(invoice, video.created_at, video.archived_at) * video.file_size.to_i
    bytehrs += video.encodings.all.sum do |encoding|
      presence_hours(invoice, encoding.file_added_at, encoding.file_removed_at) * encoding.file_size.to_i
    end
    bytehrs
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