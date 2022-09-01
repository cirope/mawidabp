class ReadingsController < ApplicationController
  respond_to :js

  before_action :auth

  # * POST /readings
  def create
    @reading = Reading.list.create!(
      user:          @auth_user,
      readable_id:   params[:id],
      readable_type: params[:type]
    )
  end
end
