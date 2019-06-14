class PermalinksController < ApplicationController
  respond_to :html

  before_action :auth
  before_action :set_permalink, only: [:show]

  # * GET /permalinks/token
  def show
    redirect_to @permalink.as_options
  end

  private

    def set_permalink
      @permalink = Permalink.find_by! token: params[:id]
    end
end
