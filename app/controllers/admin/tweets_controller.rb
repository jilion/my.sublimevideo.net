class Admin::TweetsController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('twitter') if %w[favorite].include?(action_name) }

  has_scope :keywords, :by_date
  has_scope :favorites, type: :boolean

  # GET /tweets
  def index
    params[:keywords] = 'sublimevideo' if !params[:keywords] && !params[:favorites]
    params[:by_date]  = 'desc' unless params[:by_date]
    @tweets = apply_scopes(Tweet)
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
