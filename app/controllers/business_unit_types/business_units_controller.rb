# frozen_string_literal: true

class BusinessUnitTypes::BusinessUnitsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_business_unit, only: [:edit, :update]

  # * GET /business_unit_types/1/business_units/3/edit
  def edit
    @title = t 'business_unit.edit_title'
  end

  # * PATCH /business_unit_types/1/business_units/3
  def update
    @title = t 'business_unit.edit_title'

    if @business_unit.update(business_unit_params)
      flash.notice = t 'business_unit.correctly_updated'
      redirect_to(business_unit_types_path)
    else
      render 'edit', status: :unprocessable_entity
    end
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'business_unit_type.stale_object_error'
    redirect_to 'edit', status: :unprocessable_entity
  end

  private

    def set_business_unit
      @business_unit = BusinessUnit.list.find(params[:id])
    end

    def business_unit_params
      params.require(:business_unit).permit(:name, :business_unit_type_id, :lock_version)
    end
end
