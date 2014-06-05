class BestPracticesController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_best_practice, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: :destroy

  # * GET /best_practices
  def index
    @best_practices =
      BestPractice.list.reorder('created_at DESC').page(params[:page])
  end

  # * GET /best_practices/1
  def show
    respond_with @best_practice
  end

  # * GET /best_practices/new
  def new
    @best_practice = BestPractice.new
  end

  # * GET /best_practices/1/edit
  def edit
  end

  # * POST /best_practices
  def create
    @best_practice = BestPractice.list.new best_practice_params

    @best_practice.save
    respond_with @best_practice
  end

  # * PATCH /best_practices/1
  def update
    update_resource @best_practice, best_practice_params

    unless response_body
      respond_with @best_practice, location: edit_best_practice_url(@best_practice)
    end
  end

  # * DELETE /best_practices/1
  def destroy
    unless @best_practice.destroy
      flash.alert = @best_practice.errors.full_messages.join(APP_ENUM_SEPARATOR)
    end

    respond_with @best_practice, location: best_practices_url
  end

  private
    def set_best_practice
      @best_practice = BestPractice.list.includes(
        process_controls: { control_objectives: :control }
      ).find(params[:id])
    end

    def best_practice_params
      params.require(:best_practice).permit(
        :name, :description, :lock_version, process_controls_attributes: [
          :id, :name, :order, :_destroy, control_objectives_attributes: [
            :id, :name, :relevance, :risk, :order, :_destroy, control_attributes: [
              :id, :control, :effects, :design_tests, :compliance_tests, :sustantive_tests, :_destroy
            ]
          ]
        ]
      )
    end
end
