class OptionsController < ApplicationController
  before_action :auth, :check_privileges, :set_options

  def edit
  end

  def update
    current_organization.options['manual_scores'].merge!(
      Time.zone.now.to_i => @current_scores
    )

    if current_organization.save
      redirect_to [:edit, :options], notice: t('flash.options.update.notice')
    else
      render 'edit'
    end
  end

  private

    def set_options
      @current_scores = if params.dig(:options)
                          options_params.values.to_h.
                            transform_keys(&:strip).
                            transform_values &:to_i
                        else
                          current_organization.current_scores
                        end
    end

    def options_params
      params.require(:options).permit!
    end
end
