class PollsController < ApplicationController
  before_filter :load_privileges, :auth
  before_filter :check_privileges, :except => [:edit, :update]

  layout proc { |controller|
    use_clean = [
      'edit'
    ].include?(controller.action_name)

    controller.request.xhr? ? false : (use_clean ? 'application_clean' : 'application')
  }
  # GET /polls
  # GET /polls.json
  def index
    @title = t 'poll.index_title'
    if params[:id]
      @polls = Poll.where("questionnaire_id = ?", params[:id]).paginate(
        :page => params[:page], :per_page => APP_LINES_PER_PAGE)
    else
      @polls = Poll.paginate(
        :page => params[:page], :per_page => APP_LINES_PER_PAGE
      )
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @polls }
    end
  end

  # GET /polls/1
  # GET /polls/1.json
  def show
    @title = t 'poll.show_title'
    @poll = Poll.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @poll }
    end
  end

  # GET /polls/new
  # GET /polls/new.json
  def new
    @title = t 'poll.new_title'
    @poll = Poll.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @poll }
    end
  end

  # GET /polls/1/edit
  def edit
    @title = t 'poll.edit_title'
    @poll = @auth_user.polls.find params[:id]
  end

  # POST /polls
  # POST /polls.json
  def create
    @title = t 'poll.new_title'
    @poll = Poll.new(params[:poll])

    respond_to do |format|
      if @poll.save
        format.html { redirect_to @poll, :notice => (t 'poll.correctly_created') }
        format.json { render :json => @poll, :status => :created, :location => @poll }
      else
        format.html { render :action => "new" }
        format.json { render :json => @poll.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /polls/1
  # PUT /polls/1.json
  def update
    @title = t 'poll.edit_title'
    @poll = @auth_user.polls.find params[:id]

    respond_to do |format|
      if @poll.update_attributes(params[:poll])
        format.html { redirect_to welcome_url, :notice => (t 'poll.correctly_updated') }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @poll.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'poll.stale_object_error'
    redirect_to :action => :edit
  end

  # DELETE /polls/1
  # DELETE /polls/1.json
  def destroy
    @poll = Poll.find(params[:id])
    @poll.destroy

    respond_to do |format|
      format.html { redirect_to polls_url }
      format.json { head :ok }
    end
  end

   # * GET /polls/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ["#{Organization.table_name}.id = :organization_id"]
    conditions << "#{User.table_name}.id <> :self_id" if params[:user_id]
    parameters = {
      :organization_id => @auth_organization.id,
      :self_id => params[:user_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).limit(10)

    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  def load_privileges #:nodoc:
    if @action_privileges
      @action_privileges.update(
        :auto_complete_for_user => :read
      )
    end
  end
end
