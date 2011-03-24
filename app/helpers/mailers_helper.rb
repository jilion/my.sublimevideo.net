module MailersHelper

  def signature
    "The SublimeVideo Team"
  end
  
  def intro(name = "SublimeVideo user")
    "Dear #{name},"
  end

end
