class EducationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_education, only: [:show, :edit, :update, :destroy]
  before_action :set_user
  before_action :require_admin, only: [:index, :new, :create, :edit, :destroy, :update]

  # GET /educations
  # GET /educations.json
  def index
    @page_title = 'Education'
    @per_page = params[:per_page] || 30
    @pagy, @educations = pagy(Education.all.order(created_at: :desc), items: @per_page)
  end

  # GET /educations/1
  # GET /educations/1.json
  def show
    @page_title = @education.name
  end

  # GET /educations/new
  def new
    @page_title = 'New Education'
    @education = Education.new
  end

  # GET /educations/1/edit
  def edit
    @page_title = 'Edit Education'
  end

  # POST /educations
  # POST /educations.json
  def create
    @education = Education.new(education_params)

    respond_to do |format|
      if @education.save
        format.html { redirect_to @education, notice: 'Education was successfully created.' }
        format.json { render :show, status: :created, location: @education }
      else
        format.html { render :new }
        format.json { render json: @education.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /educations/1
  # PATCH/PUT /educations/1.json
  def update
    respond_to do |format|
      if @education.update(education_params)
        format.html { redirect_to @education, notice: 'Education was successfully updated.' }
        format.json { render :show, status: :ok, location: @education }
      else
        format.html { render :edit }
        format.json { render json: @education.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /educations/1
  # DELETE /educations/1.json
  def destroy
    @education.destroy
    respond_to do |format|
      format.html { redirect_to educations_url, notice: 'Education was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def user
    @educations = Education.order(:name).limit(100)
    @educations = @educations.where("name like ?", "%#{params[:term]}%") if params[:term]

    respond_to do |format|
      format.html  # index.html.erb
      format.json  { render :json => @educations.map(&:name) }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_education
      @education ||= Education.find(params[:id])
    end

    # Never trust parameters from the scary internet
    # only allow the white list through.
    def education_params
    # extend with your own params
    accessible = %i[name address city state zipcode homepage abbreviation]
    params.require(:education).permit(accessible)
    end
end