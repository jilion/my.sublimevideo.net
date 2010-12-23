class Mail::Letter
  extend ActiveModel::Naming
  
  def initialize(params)
    @template = Mail::Template.find(params[:template_id])
    @admin_id, @criteria = params[:admin_id], params[:criteria]
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def deliver_and_log
    return nil unless @template.present? && @admin_id.present? && @criteria.present?
    
    users = case @criteria
            when 'dev'
              User.where(:email => ["thibaud@jilion.com", "remy@jilion.com", "zeno@jilion.com", "octave@jilion.com"])
            when 'all'
              User.all
            when 'invited_after_2010_12_23'
              User.where(:created_at.gt => Time.utc(2010,12,23))
            when 'with_invalid_site'
              User.beta.includes(:sites).all.select { |u| u.sites.any? { |s| !s.valid? } }
            else
              User.send(@criteria)
            end
            
    users.each { |u| self.class.delay.deliver(u, @template) }
    
    unless @criteria == 'dev'
      @template.logs.create(:admin_id => @admin_id, :criteria => @criteria, :user_ids => users.map(&:id))
    end
  end
  
private
  
  def self.deliver(user, template)
    MailMailer.send_mail_with_template(user, template).deliver
  end
  
end