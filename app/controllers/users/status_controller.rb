class Users::StatusController < ApplicationController
  include Users::Finders

  before_action :auth, :set_user, :set_title
  before_action -> { request.variant = :graph if params[:graph]  }

  # * GET /users/status/1
  def show
    @user = @auth_user if @auth_user.audited?
    @weaknesses = @user.weaknesses.list.finals(false).not_incomplete
  end
end
