class VideoMailer < SublimeVideoMailer
  
  def video_active(video)
    @video = video
    mail(:to => "#{video.user.full_name} <#{video.user.email}>", :subject => "Your video &ldquo;#{video.title}&rdquo; is now ready!")
  end
  
end