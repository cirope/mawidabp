class EMailsController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_title

  # GET /emails
  def index
    build_search_conditions EMail

    @emails = EMail.list.where(@conditions).page params[:page]
  end

  # GET /emails/1
  def show
    @email = EMail.list.find params[:id]
  end
end
