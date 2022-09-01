module Permalinks::Options
  extend ActiveSupport::Concern

  def as_options
    action_options.merge permalink_token: token
  end

  private

    def action_options
      controller, action_name = *action.split('/')

      { controller: controller, action: action_name }
    end
end
