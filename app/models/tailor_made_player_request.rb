class TailorMadePlayerRequest < ActiveRecord::Base

  attr_accessor :export_type

  mount_uploader :document, TailorMadePlayerRequestDocumentUploader

  TOPICS = %w[agency standalone platform other] unless defined? TOPICS

  # ==========
  # = Scopes =
  # ==========

  # sort
  scope :by_topic, lambda { |way='desc'| order{ topic.send(way) } }
  scope :by_date,  lambda { |way='desc'| order{ created_at.send(way) } }

end

# == Schema Information
#
# Table name: tailor_made_player_requests
#
#  company                 :string(255)
#  country                 :string(255)
#  created_at              :datetime         not null
#  description             :text             not null
#  document                :string(255)
#  email                   :string(255)      not null
#  id                      :integer          not null, primary key
#  job_title               :string(255)
#  name                    :string(255)      not null
#  token                   :string(255)
#  topic                   :string(255)      not null
#  topic_other_detail      :string(255)
#  topic_standalone_detail :string(255)
#  updated_at              :datetime         not null
#  url                     :string(255)
#

