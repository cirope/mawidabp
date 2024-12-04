class OptionsController < ApplicationController
  before_action :auth, :check_privileges, :set_options

  def index
  end

  def edit
  end

  def update
    if @organization.update options_params
      redirect_to options_path
    else
      render 'edit'
    end
  end

  private

    def set_options
      @current_scores = current_organization.current_scores
    end

    def options_params
      params.require(:organization).permit options: {}
    end
end
