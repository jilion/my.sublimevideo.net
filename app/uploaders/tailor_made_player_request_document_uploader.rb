# encoding: utf-8
class TailorMadePlayerRequestDocumentUploader < CarrierWave::Uploader::Base

  def fog_public
    false
  end

  def fog_directory
    S3Wrapper.buckets['tailor_made_player_requests']
  end

end
