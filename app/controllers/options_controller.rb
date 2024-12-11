class OptionsController < ApplicationController
  before_action :auth, :check_privileges, :set_option_type
  before_action :set_options, only: [:update]

  def create
  end

  def edit
  end

  def update
    options = current_organization.options[@type] ||= {}
    current_organization.option_type                = @type

    options.merge! Time.zone.now.to_i => @current_scores

    if current_organization.save
      redirect_to [:edit, :options, type: @type],
        notice: t('flash.options.update.notice')
    else
      render 'edit'
    end
  end

  private

    def set_option_type
      @type = params[:type] ||= 'manual_scores'
    end

    def set_options
      @current_scores = if params.dig('options')
                          options_params.values.to_h.
                            transform_keys(&:strip).transform_values &:to_i
                        else
                          {}
                        end
    end

    def options_params
      params.require(:options).permit!
    end
end
