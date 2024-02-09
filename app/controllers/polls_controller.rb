class PollsController < ApplicationController
  include AutoCompleteFor::BusinessUnit

  before_action :load_privileges, :auth, except: [:edit, :update, :show]
  before_action :check_privileges, except: [:edit, :update, :show]
  before_action :set_poll, only: [:show, :edit, :update, :destroy]
  before_action :set_questionnaire, only: [:index]
  before_action :set_title, except: :destroy
  before_action :set_current_module, except: [:reports]

  # GET /polls
  # GET /polls.json
  def index
    @polls = (@questionnaire&.polls || Poll.list).
      includes(:questionnaire, :user).
      search(**search_params).
      default_order.
      references(:questionnaire, :user).
      page params[:page]
  end

  # GET /polls/1
  def show
  end

  # GET /polls/new
  def new
    @poll = Poll.new
  end

  # GET /polls/1/edit
  def edit
    if @poll.nil?
      redirect_to login_url, alert: t('polls.not_found')
    elsif @poll.answered? || (params[:token] != @poll.access_token)
      redirect_to @poll
    end
  end

  # POST /polls
  def create
    @poll = Poll.list.new poll_params

    polls = Poll.between_dates(Date.today.at_beginning_of_day, Date.today.end_of_day).where(
      questionnaire_id: @poll.questionnaire_id, user_id: @poll.user_id
    )

    respond_to do |format|
      if polls.present?
        format.html { redirect_to new_poll_path, alert: t('polls.already_exists', user: @poll.user&.full_name) }
      elsif @poll.save
        format.html { redirect_to @poll }
      else
        format.html { render 'new' }
      end
    end
  end

  # PATCH /polls/1
  def update
    if @poll.update poll_params
      redirect_with_notice @poll
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # DELETE /polls/1
  def destroy
    @poll.destroy
    redirect_with_notice @poll
  end

  def reports
  end

  private

    def poll_params
      params.require(:poll).permit(
        :user_id, :questionnaire_id, :comments, :lock_version,
        :about_id, :about_type,
        answers_attributes: [
          :id, :answer, :comments, :answer_option_id, :type,
          :attached, :attached_cache, :remove_attached
        ]
      )
    end

    def set_questionnaire
      @questionnaire = Questionnaire.list.find_by id: params[:questionnaire_id]
    end

    def set_poll
      @poll = Poll.list.preload(answers: { question: :answer_options }).find params[:id]
    end

    def set_current_module
      @current_module = 'administration_questionnaires_polls'
    end

    def load_privileges
      @action_privileges.update(
        reports: :read,
        auto_complete_for_business_unit: :read
      ) if @action_privileges
    end
 end
