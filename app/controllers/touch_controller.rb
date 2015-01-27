class TouchController < ApplicationController
  before_action :auth

  def index
    head :ok
  end
end
