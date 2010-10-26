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
    
    users = User
    users = if @criteria.is_a?(Array)
      @criteria.each { |c| users = users.send(c) }
      users
    else
      users.send(@criteria)
    end.all
    
    users.each { |u| self.class.delay.deliver(u, @template) }
    
    @template.logs.create(:admin_id => @admin_id, :criteria => @criteria, :user_ids => users.map(&:id))
  end
  
private
  
  def self.deliver(user, template)
    MailMailer.send_mail_with_template(user, template).deliver
  end
  
end