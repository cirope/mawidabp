class EMailsController < ApplicationController
  before_filter :auth, :check_privileges
  
  # GET /emails
  # GET /emails.json
  def index
    @title = t 'email.index_title'
    @emails = EMail.order('created_at DESC').paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @emails }
    end
  end

  # GET /emails/1
  # GET /emails/1.json
  def show
    @title = t 'email.show_title'
    @email = EMail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @email }
    end
  end
end
