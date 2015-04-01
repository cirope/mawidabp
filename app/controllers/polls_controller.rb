class PollsController < ApplicationController
  before_action :load_privileges, :auth, except: [:edit, :update, :show]
  before_action :check_privileges, except: [:edit, :update, :show]
  before_action :set_poll, only: [:show, :edit, :update, :destroy]
  before_action :set_questionnaire, only: [:index]
  before_action :set_title, except: :destroy
  before_action :set_current_module, except: [:reports]

  respond_to :html

  require 'csv'

  # GET /polls
  # GET /polls.json
  def index
    @polls = @questionnaire.polls if @questionnaire

    build_search_conditions Poll

    @polls = (@polls || Poll.list).includes(:questionnaire, :user).
      where(@conditions).order("#{Poll.quoted_table_name}.#{Poll.qcn('created_at')} DESC").
      references(:questionnaire, :user).page(params[:page])

    respond_with @polls
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
        format.html { redirect_to new_poll_path, alert: t('polls.already_exists') }
      elsif @poll.save
        format.html { redirect_to @poll }
      else
        format.html { render 'new' }
      end
    end
  end

  # PATCH /polls/1
  def update
    update_resource @poll, poll_params
    respond_with @poll, location: poll_url(@poll) unless response_body
  end

  # DELETE /polls/1
  def destroy
    @poll.destroy
    respond_with @poll
  end

  def reports
  end

  def import_csv_customers
    @title = t('polls.import_csv')
  end

  def send_csv_polls
    ext = File.extname(params[:poll][:file].original_filename) rescue ''

    if ext.downcase == '.csv'
      n = process_csv params[:poll][:file].path

      flash[:notice] = t('polls.customer_polls_sended', count: n)
    else
      flash[:alert] = t('polls.error_csv_file_extension')
    end

    respond_to do |format|
      format.html { redirect_to import_csv_customers_polls_path }
    end
  end

  private

    def poll_params
      params.require(:poll).permit(
        :user_id, :questionnaire_id, :comments, :lock_version,
        answers_attributes: [
          :id, :answer, :comments, :answer_option_id, :type
        ]
      )
    end

    def set_questionnaire
      @questionnaire = Questionnaire.list.find_by id: params[:questionnaire_id]
    end

    def set_poll
      @poll = Poll.list.find params[:id]
    end

    def process_csv file_name
      count = 0

      CSV.foreach(file_name, col_sep: ',', encoding: 'UTF-8') do |row|
        poll = current_organization.polls.new(
          customer_email: row[0], customer_name: row[1],
          questionnaire_id: params[:poll][:questionnaire].to_i
        )
        count += 1 if poll.save
      end

      count
    end

    def set_current_module
      @current_module = 'administration_questionnaires_polls'
    end

    def load_privileges
      if @action_privileges
        @action_privileges.update reports: :read, import_csv_customers: :read
      end
    end
 end
