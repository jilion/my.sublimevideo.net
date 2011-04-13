class Admin::TweetsController < Admin::AdminController
  respond_to :js, :html

  has_scope :keywords
  has_scope :favorites
  has_scope :by_date
  # has_scope :by_retweets_count

  # GET /admin/users
  def index
    params[:keywords] = 'sublimevideo' if !params[:keywords] && !params[:favorites]
    # @tweets = apply_scopes(Tweet.where(retweeted_tweet_id: nil)).by_date # don't fetch retweets
    @tweets = apply_scopes(Tweet).by_date
    # @retweets = apply_scopes(Tweet.excludes(retweeted_tweet_id: nil))
    respond_with(@tweets, :per_page => 50)
  end

  # PUT /admin/tweets/:id/favorite
  def favorite
    @tweet = Tweet.find(params[:id])
    @tweet.favorite!
    respond_to do |format|
      format.js
      format.html { redirect_to [:admin, :tweets] }
    end
  end

end
