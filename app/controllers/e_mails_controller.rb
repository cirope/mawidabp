class EMailsController < ApplicationController

  before_action :auth, :check_privileges
  before_action :set_title

  # GET /emails
  def index
    @emails = EMail.list.search(**search_params).page params[:page]
  end

  # GET /emails/1
  def show
    @email = EMail.list.find params[:id]
  end
end
