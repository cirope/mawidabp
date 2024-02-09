class ClosingInterviewsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_closing_interview, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /closing_interviews
  def index
    @closing_interviews = ClosingInterview.list.
      includes(review: :plan_item).
      references(:reviews, :plan_items).
      search(**search_params).
      merge(Review.allowed_by_business_units).
      order(interview_date: :desc).
      page params[:page]
  end

  # GET /closing_interviews/1
  def show
    respond_to do |format|
      format.html
      format.pdf  { redirect_to closing_interview_pdf_path }
    end
  end

  # GET /closing_interviews/new
  def new
    @closing_interview = ClosingInterview.list.new

    respond_to do |format|
      format.html
      format.js   { @review = Review.list.find_by id: params[:review_id] }
    end
  end

  # GET /closing_interviews/1/edit
  def edit
  end

  # POST /closing_interviews
  def create
    @closing_interview = ClosingInterview.list.new closing_interview_params

    if @closing_interview.save
      redirect_with_notice @closing_interview
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /closing_interviews/1
  def update
    if @closing_interview.update closing_interview_params
      redirect_with_notice @closing_interview
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # DELETE /closing_interviews/1
  def destroy
    @closing_interview.destroy
    redirect_with_notice @closing_interview
  end

  private

    def set_closing_interview
      @closing_interview = ClosingInterview.list.find params[:id]
    end

    def closing_interview_params
      params.require(:closing_interview).permit :interview_date,
        :findings_summary, :recommendations_summary, :suggestions, :comments,
        :audit_comments, :responsible_comments, :review_id, :lock_version,
        responsibles_attributes: [:id, :kind, :user_id, :_destroy],
        auditors_attributes: [:id, :kind, :user_id, :_destroy],
        assistants_attributes: [:id, :kind, :user_id, :_destroy]
    end

    def closing_interview_pdf_path
      @closing_interview.to_pdf current_organization

      @closing_interview.relative_pdf_path.tap do |path|
        FileRemoveJob.set(wait: 15.minutes).perform_later path
      end
    end
end
