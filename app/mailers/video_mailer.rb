class VideoMailer < SublimeVideoMailer
  
  def video_active(video)
    @video = video
    mail(:to => "#{video.user.full_name} <#{video.user.email}>", :subject => "Your video “#{video.title}” is now ready!")
  end
  
end