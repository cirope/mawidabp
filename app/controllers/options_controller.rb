class OptionsController < ApplicationController
  before_action :auth, :check_privileges, :set_type
  before_action :set_options, only: [:update]

  def edit
  end

  def update
    current_organization.options[@type].merge!(
      Time.zone.now.to_i => @current_scores
    )

    if current_organization.save
      redirect_to [:edit, :options], notice: t('flash.options.update.notice')
    else
      render 'edit'
    end
  end

  private

    def set_type
      @type = params[:type] || 'manual_scores'
    end

    def set_options
      @current_scores = options_params.values.to_h.
                          transform_keys(&:strip).
                          transform_values &:to_i
    end

    def options_params
      params.require(:options).permit!
    end
end
