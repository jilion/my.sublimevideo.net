class Www::PressReleasesController < ApplicationController

  def show
    render params[:page]
  end

end
