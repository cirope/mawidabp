class TouchController < ApplicationController
  before_action :auth

  def create
    head :ok
  end
end
