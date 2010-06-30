# == Schema Information
#
# Table name: users
#
#  video_settings :text
#

module User::VideoSettings
  
  # ===================================
  # = User instance methods extension =
  # ===================================
  
  def use_webm?
    video_settings[:webm] == "1"
  end
  
  def default_video_embed_width
    video_settings[:default_video_embed_width]
  end
  
protected
  
  def set_default_video_settings
    self.video_settings ||= {}
    self.video_settings[:webm] = "0" unless video_settings.key?(:webm)
    # TODO define this default
    self.video_settings[:default_video_embed_width] = video_settings.key?(:default_video_embed_width) && video_settings[:default_video_embed_width].to_i >= 100 ? video_settings[:default_video_embed_width].to_i : 600
  end
  
end