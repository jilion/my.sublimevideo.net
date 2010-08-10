module ApplicationHelper
  
  def public?
    MySublimeVideo::Release.public?
  end
  
end