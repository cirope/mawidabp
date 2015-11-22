class Fortresses::UsersController < ApplicationController
  include Users::Searches

  def index
    render template: 'users/index'
  end
end
