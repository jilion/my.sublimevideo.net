class Www::PressReleasesController < ApplicationController

  def show
    @body_class = 'press_release'
    render params[:page]
  end

end
