#############################
########### USAGE ###########
#############################
#
# Send a notification that a new user has signed up.
# Ding.signup()
#
# Send a notification that a new plan has been created (cycle yearly or monthly).
# Ding.plan_added(plan_name, cycle, amount_paid)
#
# Send a notification that a plan has been cancelled.
# Ding.plan_removed(plan_name, cycle, amount_refunded)
#
# Send a notification that a plan has been moved (amount_paid can be negative in case of refund).
# Ding.plan_updated(from_plan_name, to_plan_name, amount_paid) - REMOVED !!
#

require 'socket'
require 'openssl'
require 'timeout'

class Ding
  @@hostName = 'team.jime.com'
  @@port = 5678

  # check whether the plan name is a valid one.
  def self.valid_plan(plan_name=nil)
    return plan_name != nil && plan_name != ""
  end

  def self.is_number(number)
    return number.is_a? Numeric
  end

  # notify the Ding servers that a user has signed up.
  def self.signup
    self.send("{\"action\":\"signup\"}")
  end

  # notify the Ding servers that a plan with the given name has been added.
  def self.plan_added(plan_name=nil, cycle=nil, amount_paid=0)
    amount = self.is_number(amount_paid) ? amount_paid : 0
    if self.valid_plan(plan_name)
      self.send("{\"action\":\"add\",\"plan_name\":\"" + plan_name.to_s + "\",\"cycle\":\"" + cycle.to_s + "\",\"amount\":" + amount.to_s + "}")
    end
  end

  # notify the Ding servers that a plan with the given name has been removed.
  def self.plan_removed(plan_name=nil, cycle=nil, amount_refunded=0)
    amount = self.is_number(amount_refunded) ? amount_refunded : 0
    if self.valid_plan(plan_name)
      self.send("{\"action\":\"remove\",\"plan_name\":\"" + plan_name.to_s + "\",\"cycle\":\"" + cycle.to_s + "\",\"amount\":" + amount.to_s + "}")
    end
  end

  # connect to the Ding servers and send the given message.
  def self.send(message)
    Timeout::timeout(0.5) do
      begin
        socket                = TCPSocket.open(@@hostName, @@port)
        ssl_context           = OpenSSL::SSL::SSLContext.new()
        ssl_context.cert      = OpenSSL::X509::Certificate.new(File.open(Rails.root.join('config', 'ding', 'server-cert.pem')))
        ssl_context.key       = OpenSSL::PKey::RSA.new(File.open(Rails.root.join('config', 'ding', 'server-key.pem')))
        ssl_socket            = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
        ssl_socket.sync_close = true
        ssl_socket.connect
        ssl_socket.print(message)
      rescue => ex
        puts "Could not contact Ding servers!"
        puts ex.inspect
      ensure
        ssl_socket.close unless ssl_socket.nil?
      end
    end
  rescue
    puts "Timeout"
  end

end