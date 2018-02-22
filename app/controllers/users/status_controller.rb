class Users::StatusController < ApplicationController
  include Users::Finders

  before_action :auth, :set_title
  before_action :set_user, only: [:show, :create, :destroy]
  before_action -> { request.variant = :graph if params[:graph]  }

  # * GET /users/status
  def index
    user_ids = status_session.dup

    status_session.clear

    redirect_to findings_url(completed: 'incomplete', user_ids: user_ids)
  end

  # * GET /users/status/1
  def show
    @user = @auth_user if @auth_user.audited?
    @weaknesses = @user.weaknesses.list.finals(false).not_incomplete
  end

  # * POST /users/status
  def create
    status_session.concat([@user.id]).uniq!
  end

  # * DELETE /users/status/1
  def destroy
    status_session.delete @user.id
  end

  private

    def status_session
      session[:status_user_ids] ||= []
    end
    helper_method :status_session
end
