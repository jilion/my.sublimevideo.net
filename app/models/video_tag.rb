class VideoTag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :st, :type => String # Site token
  field :u,  :type => String # Video uid

  field :uo, :type => String # Video uid origin
  field :n,  :type => String # Video name
  field :no, :type => String # Video name origin
  field :p,  :type => String # Video poster url
  field :cs, :type => Array  # Video current sources array (cs) ['5062d010' (video source crc32), 'abcd1234', ... ] # sources actually used in the video tag
  field :s,  :type => Hash   # Video sources hash (s) { '5062d010' (video source crc32) => { u (source url) => 'http://.../dartmoor.mp4', q (quality) => 'hd', f (family) => 'mp4', r (resolution) => '320x240' }, ... }

  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING]]

  def site
    Site.find_by_token(st)
  end

  # ====================
  # = Instance Methods =
  # ====================

  def update_with_latest_data(attributes)
    %w[uo n no p cs].each do |key|
      self.send("#{key}=", attributes[key])
    end
    # Properly change sources without falsely trig dirty attribute tracking
    current_sources = self.read_attribute('s')
    new_sources     = current_sources.merge(attributes['s'])
    self.s = new_sources if current_sources != new_sources

    save
  end

  # =================
  # = Class Methods =
  # =================

  def self.create_or_update_from_trackers!(trackers)
    video_tags = video_tags_from_trackers(trackers)
    video_tags.each do |keys, attrs|
      attrs[:st], attrs[:u] = keys
      if video_tag = VideoTag.where(st: attrs[:st], u: attrs[:u]).first
        video_tag.update_with_latest_data(attrs)
      else
        VideoTag.create(attrs)
      end
    end
  end

private

  # Merge each videos tag in one big hash
  #
  # { ['site_token','video_uid'] => { uo: ..., n: ..., cs: ['5062d010',...], s: { '5062d010' => { ...}, ... } } }
  #
  def self.video_tags_from_trackers(trackers)
    trackers   = only_video_tags_trackers(trackers)
    video_tags = Hash.new { |h,k| h[k] = Hash.new }
    trackers.each do |request, hits|
      params = Addressable::URI.parse(request).query_values || {}
      if all_needed_params_present?(params)
        %w[uo n no p cs].each do |key|
          video_tags[[params['t'],params['vu']]][key] = params["v#{key}"]
        end
        # Video sources
        video_tags[[params['t'],params['vu']]]['s'] ||= {}
        video_tags[[params['t'],params['vu']]]['s'][params['vc']] = { 'u' => params['vs'], 'q' => params['vsq'], 'f' => params['vsf'] }
        video_tags[[params['t'],params['vu']]]['s'][params['vc']]['r'] = params['vsr'] if params['vsr'].present?
      end
    end
    video_tags
  end

  def self.only_stats_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :video_tags }.categories
  end

  def self.all_needed_params_present?(params)
    query_keys = %w[t vu vuo vn vno vs vc vcs vsq vsf vp]
    (params.keys & query_keys).sort == query_keys.sort
  end

end
