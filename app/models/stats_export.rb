class StatsExport
	include Mongoid::Document
  include Mongoid::Uniquify
	include Mongoid::Timestamps

	key :token

  field :token
	field :st
	field :from, type: DateTime
	field :to, type: DateTime

	index :st

  mount_uploader :file, StatsExportUploader

	attr_accessible :st, :from, :to, :file

	validates :st,   presence: true
	validates :from, presence: true
	validates :to,   presence: true
	validates :file, presence: true

  uniquify :token, chars: Array('a'..'z') + Array('0'..'9')

	def site
		Site.find_by_token(st)
	end

end
