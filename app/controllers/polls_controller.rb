class PollsController < ApplicationController
  before_filter :auth
  
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

  # GET /polls/1/edit
  def edit
    @title = t 'poll.edit_title'
    @poll = Poll.find(params[:id])
  end

  # PUT /polls/1
  # PUT /polls/1.json
  def update
    @title = t 'poll.edit_title'
    @poll = Poll.find(params[:id])
             
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
end
