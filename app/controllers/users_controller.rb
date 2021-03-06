class UsersController < ApplicationController
  include Pagy::Frontend
  before_action :authenticate_user!
  before_action :set_user, only: %i[liked disliked]
  before_action :set_user_admin, only: %i[show edit update]
  before_action :require_admin, only: %i[destroy index]
  before_action :set_user_reviews, only: %i[liked disliked]
  before_action :set_per_page, only: %i[liked disliked]

  # GET /users
  # GET /users.json
  def index
    @page_title = 'Accounts'
    @pagy, @users = pagy(User.all.order(created_at: :desc), items: 99)
  end

  # GET /users/:id.:format
  def show
    @page_title = @user.name
    # if @user == current_user || @user in current_user.friendships
    @pagy_friendships, @friendships = pagy(@user.friendships.order(created_at: :desc), page_param: :page_friends, params: { active_tab: 'friends-tab' } )
    @pagy_reviews, @reviews = pagy(@user.reviews.includes(:movie).order(created_at: :desc), page_param: :page_reviews, params: { active_tab: 'reviews-tab' })
    @pagy_recommendations, @recommendations = pagy(@user.movie_user_recommendations.includes(:movie).order(created_at: :desc), page_param: :page_recommendations, params: { active_tab: 'recommendations-tab' })
    @pagy_lists, @lists = pagy(@user.lists.includes(:movies).order(created_at: :desc), page_param: :page_lists, params: { active_tab: 'lists-tab' })
    @friendships_count = if @friendships.blank?
                       0
                     else
                       @user.friendships.count
                     end
    if @reviews.blank?
      @avg_review = 0
      @number_of_reviews = 0
      @number_of_liked_movies = 0
      @number_of_disliked_movies = 0
    else
      @number_of_reviews = @user.reviews.count
      @avg_review = @user.reviews.average(:rating).round(2)
      @number_of_liked_movies = Review.where(user_id: @user, rating: 5).count
      @number_of_disliked_movies = Review.where(user_id: @user, rating: 1).count
    end

    if @recommendations.blank?
      @number_of_recommendations = 0
    else
      @number_of_recommendations = @user.movie_user_recommendations.count
    end
  end

  # GET /users/:id/edit
  def edit
    @page_title = 'Edit Account'
  end

  # PATCH/PUT /users/:id.:format
  def update
    @page_title = 'Edit Account'
    # authorize! :update, @user_edit
    respond_to do |format|
      if @user.update(user_params)
        # Sign in the user bypassing validation
        # bypass_sign_in(@user_edit)
        format.html { redirect_to user_path, notice: 'Your profile was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/:id.:format
  def destroy
    # authorize! :delete, @user
    @user_destroy = User.find(params[:id])
    @user_destroy.reviews.each(&:destroy)
    @user_destroy.friendships.each(&:destroy)
    @user_destroy.movie_user_recommendations.each(&:destroy)
    # @user.movies.each(&:destroy)

    if @user_destroy.destroy
      flash[:notice] = 'User Removed'
      redirect_to users_path
    else
      render 'destroy'
    end
  end

  def liked
    @page_title = 'Liked Movies'
    @movie_user = @user.check_user(params[:user_id])
    # params.except[:user_id]
    # params.delete :user_id
    @pagy_likes, @likes = pagy(Review.where(user_id: @movie_user.id, rating: 5).order(created_at: :desc), page_param: :page_liked)
  end

  def disliked
    @page_title = 'Disliked Movies'
    @movie_user = @user.check_user(params[:user_id])
    # params.except[:user_id]
    # params.delete :user_id
    @pagy_dislikes, @dislikes = pagy(Review.where(user_id: @movie_user.id, rating: 1).order(created_at: :desc), page_param: :page_disliked)
  end

  private

  def set_user_admin
    if current_user.super_admin?
       @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

  def user_params
    # extend with your own params
    accessible = %i[name email gender hometown location education_name education_level politics birthday link]
    params.require(:user).permit(accessible)
  end
end
