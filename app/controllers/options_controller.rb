class OptionsController < ApplicationController
  before_action :auth, :check_privileges, :set_organization

  def index
  end

  def edit
  end

  def update
  end

  private

    def set_organization
      @organization = current_organization
    end
end
