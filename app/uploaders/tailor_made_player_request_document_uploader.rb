# encoding: utf-8
require_dependency 's3'

class TailorMadePlayerRequestDocumentUploader < CarrierWave::Uploader::Base

  def fog_public
    false
  end

  def fog_directory
    S3.buckets['tailor_made_player_requests']
  end

end
