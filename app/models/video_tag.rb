# encoding: utf-8

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
      self.send("#{key}=", attributes[key]) if attributes[key].present?
    end
    # Properly update sources
    self.s = read_attribute('s').merge(attributes['s']) if attributes['s'].present?

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
      Rails.logger.info "site token: #{attrs[:st]} (encoding: #{attrs[:st].encoding})"
      Rails.logger.info "video uid: #{attrs[:u]} (encoding: #{attrs[:u].encoding})"

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
    if changed?
      channel = Pusher["private-#{st}"]
      if channel.stats[:occupied]
        channel.trigger('video_tag', u: u, meta_data: meta_data)
      end
    end
  rescue Pusher::HTTPError
    # do nothing
  end

  # Merge each videos tag in one big hash
  #
  # { ['site_token','video_uid'] => { uo: ..., n: ..., cs: ['5062d010',...], s: { '5062d010' => { ...}, ... } } }
  #
  def self.video_tags_from_trackers(trackers)
    trackers   = only_video_tags_trackers(trackers)
    video_tags = Hash.new { |h,k| h[k] = Hash.new }
    trackers.each do |request, hits|
      begin
        params = Addressable::URI.parse(request).query_values || {}
        if %w[m e].include?(params['h'])
          case params['e']
          when 'l'
            if all_needed_params_present?(params, %w[vu pz])
              params['vu'].each_with_index do |vu, index|
                video_tags[[params['t'],vu]]['z'] = params['pz'][index]
              end
            end
          when 's'
            if all_needed_params_present?(params, %w[t vu vuo vn vno vs vc vcs vsq vsf])
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
      rescue => ex
        Notify.send("VideoTag parsing failed (request: '#{request}'): #{ex.message}", exception: ex)
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
