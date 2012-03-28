class Admin::TweetsController < Admin::AdminController
  respond_to :js, :html

  has_scope :keywords
  has_scope :favorites
  has_scope :by_date

  # GET /tweets
  def index
    params[:keywords] = 'sublimevideo' if !params[:keywords] && !params[:favorites]
    @tweets = apply_scopes(Tweet).by_date
    respond_with(@tweets, per_page: 50)
  end

  # PUT /tweets/:id/favorite
  def favorite
    @tweet = Tweet.find(params[:id])
    @tweet.favorite!
    respond_to do |format|
      format.js
      format.html { redirect_to [:admin, :tweets] }
    end
  end

end
