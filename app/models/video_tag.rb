class VideoTag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :st, type: String # Site token
  field :u,  type: String # Video uid

  field :uo, type: String # Video uid origin
  field :n,  type: String # Video name
  field :no, type: String # Video name origin
  field :p,  type: String # Video poster url
  field :z,  type: String # Player size
  field :cs, type: Array, default: [] # Video current sources array (cs) ['5062d010' (video source crc32), 'abcd1234', ... ] # sources actually used in the video tag
  field :s,  type: Hash,  default: {} # Video sources hash (s) { '5062d010' (video source crc32) => { u (source url) => 'http://.../dartmoor.mp4', q (quality) => 'hd', f (family) => 'mp4', r (resolution) => '320x240' }, ... }

  index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING]]

  def site
    Site.find_by_token(st)
  end

  # =============
  # = Callbacks =
  # =============

  after_save :push_new_meta_data

  # ====================
  # = Instance Methods =
  # ====================

  def update_with_latest_data(attributes)
    %w[uo n no p cs z].each do |key|
      self.send("#{key}=", attributes[key])
    end
    # Properly change sources without falsely trig dirty attribute tracking
    if attributes.key?('s')
      current_sources = self.read_attribute('s')
      new_sources     = current_sources.merge(attributes['s'])
      self.s = new_sources if current_sources != new_sources
    end

    save
  end

  def meta_data
    attributes.slice("uo", "n", "no", "p", "cs", "s", "z")
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

  # after_save
  def push_new_meta_data
    Pusher["private-#{st}"].trigger('video_tags', { u: u, meta_data: meta_data }.to_json)
  end

  # Merge each videos tag in one big hash
  #
  # { ['site_token','video_uid'] => { uo: ..., n: ..., cs: ['5062d010',...], s: { '5062d010' => { ...}, ... } } }
  #
  def self.video_tags_from_trackers(trackers)
    trackers   = only_video_tags_trackers(trackers)
    video_tags = Hash.new { |h,k| h[k] = Hash.new }
    trackers.each do |request, hits|
      params = Addressable::URI.parse(CGI.unescape(request)).query_values || {}
      case params['e']
      when 'l'
        if all_needed_params_present?(params, %w[vu pz])
          params['vu'].each_with_index do |vu, index|
            video_tags[[params['t'],vu]]['z'] = params['pz'][index]
          end
        end
      when 's'
        if all_needed_params_present?(params, %w[t vu vuo vn vno vs vc vcs vsq vsf vp])
          %w[uo n no p cs].each do |key|
            video_tags[[params['t'],params['vu']]][key] = params["v#{key}"]
          end
          # Video sources
          video_tags[[params['t'],params['vu']]]['s'] ||= {}
          video_tags[[params['t'],params['vu']]]['s'][params['vc']] = { 'u' => params['vs'], 'q' => params['vsq'], 'f' => params['vsf'] }
          video_tags[[params['t'],params['vu']]]['s'][params['vc']]['r'] = params['vsr'] if params['vsr'].present?
        end
      end
    end
    video_tags
  end

  def self.only_video_tags_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :video_tags }.categories
  end

  def self.all_needed_params_present?(params, keys)
    (params.keys & keys).sort == keys.sort
  end

end
