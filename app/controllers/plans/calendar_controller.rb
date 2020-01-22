class Plans::CalendarController < ApplicationController
  respond_to :html

  before_action :auth,
                :check_privileges,
                :set_title,
                :set_plan,
                :set_business_unit_type,
                :set_business_units

  before_action -> { request.variant = :project if params[:project]  }

  def show
  end

  private

    def set_plan
      @plan = Plan.list.find params[:id]
    end

    def set_business_unit_type
      if params[:business_unit_type].to_i > 0
        @business_unit_type = BusinessUnitType.list.find params[:business_unit_type]
      end
    end

    def set_business_units
      @business_units = if @business_unit_type
                          @plan.business_units.where(
                            business_unit_type_id: @business_unit_type.id
                          )
                        elsif params[:business_unit_type] == 'nil'
                          @plan.business_units.none
                        else
                          @plan.business_units
                        end
    end
end
