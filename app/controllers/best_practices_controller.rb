# frozen_string_literal: true

class BestPracticesController < ApplicationController
  include AutoCompleteFor::Tagging

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

    if @best_practice.save
      redirect_with_notice @best_practice, url: [:edit, @best_practice]
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # * PATCH /best_practices/1
  def update
    if @best_practice.update best_practice_params

      redirect_to_index = @best_practice.obsolete &&
                          @best_practice.errors.empty? &&
                          hide_obsolete_best_practices != '0'

      location = redirect_to_index ? best_practices_url : [:edit, @best_practice]

      redirect_with_notice @best_practice, url: location
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # * DELETE /best_practices/1
  def destroy
    @best_practice.destroy
    redirect_with_notice @best_practice
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
            :id, :name, :relevance, :risk, :obsolete, :support, :support_cache,
            :audit_sector, :date_charge, :order, :_destroy, :remove_support,
            taggings_attributes: [:id, :tag_id, :_destroy],
            control_attributes:  [
              :id, :control, :effects, :design_tests, :compliance_tests, :sustantive_tests, :_destroy,
            ],
            control_objective_auditors_attributes: [
              :id, :user_id, :_destroy
            ]
          ]
        ]
      )
    end

    def hide_obsolete_best_practices
      setting = Current.organization.settings.find_by name: 'hide_obsolete_best_practices'

      if setting
        setting.value
      else
        DEFAULT_SETTINGS[:hide_obsolete_best_practices][:value]
      end
    end

    def load_privileges
      @action_privileges.update auto_complete_for_tagging: :read
    end
end
