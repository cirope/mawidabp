class Workflows::UsersController < ApplicationController
  include Users::Searches

  def index
    render template: "users/index.#{request.format.symbol}"
  end
end
