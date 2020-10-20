class BestPracticesController < ApplicationController
  include AutoCompleteFor::Tagging

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_best_practice, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: :destroy

  # * GET /best_practices
  def index
    @best_practices = BestPractice.list.
      visible.
      search(**search_params).
      ordered.
      page params[:page]
  end

  # * GET /best_practices/1
  def show
    respond_to do |format|
      format.html
      format.csv  {
        render csv: @best_practice.to_csv, filename: @best_practice.csv_filename
      }
    end
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
    @best_practice = BestPractice.new best_practice_params

    @best_practice.save
    respond_with @best_practice, location: edit_best_practice_url(@best_practice)
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
    @best_practice.destroy

    respond_with @best_practice, location: best_practices_url
  end

  private

    def set_best_practice
      @best_practice = BestPractice.list.includes({
        process_controls: :control_objectives
      }).merge(
        ProcessControl.visible
      ).references(
        :process_controls
      ).find params[:id]

    end

    def best_practice_params
      params.require(:best_practice).permit(
        :name, :description, :obsolete, :shared, :lock_version,
        process_controls_attributes: [
          :id, :name, :order, :obsolete, :_destroy,
          control_objectives_attributes: [
            :id, :name, :relevance, :risk, :obsolete, :score_type, :support,
            :support_cache, :order, :_destroy,
            taggings_attributes: [:id, :tag_id, :_destroy],
            control_attributes:  [
              :id, :control, :effects, :design_tests, :compliance_tests, :sustantive_tests, :_destroy,
            ]
          ]
        ]
      )
    end

    def load_privileges
      @action_privileges.update auto_complete_for_tagging: :read
    end
end
