module VideosControllerHelper

  def _set_video_tag
    @video_tag = VideoTag.find(params[:video_tag_id] || params[:id], _site_token: @site.token)
  rescue ActiveRecord::RecordNotFound
    redirect_to site_video_tags_path(@site)
  end

end
