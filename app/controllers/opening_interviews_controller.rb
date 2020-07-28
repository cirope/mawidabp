class OpeningInterviewsController < ApplicationController
  respond_to :html, :js

  before_action :auth, :check_privileges
  before_action :set_opening_interview, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /opening_interviews
  def index
    @opening_interviews = OpeningInterview.list.
      includes(review: :plan_item).
      references(:reviews, :plan_items).
      search(**search_params).
      merge(Review.allowed_by_business_units).
      order(interview_date: :desc).
      page params[:page]
  end

  # GET /opening_interviews/1
  def show
    respond_to do |format|
      format.html
      format.pdf  { redirect_to opening_interview_pdf_path }
    end
  end

  # GET /opening_interviews/new
  def new
    @opening_interview = OpeningInterview.list.new

    respond_to do |format|
      format.html
      format.js   { @review = Review.list.find_by id: params[:review_id] }
    end
  end

  # GET /opening_interviews/1/edit
  def edit
  end

  # POST /opening_interviews
  def create
    @opening_interview = OpeningInterview.list.new opening_interview_params

    @opening_interview.save

    respond_with @opening_interview
  end

  # PATCH/PUT /opening_interviews/1
  def update
    update_resource @opening_interview, opening_interview_params

    respond_with @opening_interview
  end

  # DELETE /opening_interviews/1
  def destroy
    @opening_interview.destroy

    respond_with @opening_interview
  end

  private

    def set_opening_interview
      @opening_interview = OpeningInterview.list.find params[:id]
    end

    def opening_interview_params
      params.require(:opening_interview).permit :interview_date, :start_date,
        :end_date, :objective, :program, :scope, :suggestions, :comments,
        :review_id, :lock_version,
        responsibles_attributes: [:id, :kind, :user_id, :_destroy],
        auditors_attributes: [:id, :kind, :user_id, :_destroy],
        assistants_attributes: [:id, :kind, :user_id, :_destroy]
    end

    def opening_interview_pdf_path
      @opening_interview.to_pdf current_organization

      @opening_interview.relative_pdf_path.tap do |path|
        FileRemoveJob.set(wait: 15.minutes).perform_later path
      end
    end
end
