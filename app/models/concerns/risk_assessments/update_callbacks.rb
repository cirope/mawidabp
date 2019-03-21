module RiskAssessments::UpdateCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :check_if_can_be_modified
  end

  def can_be_modified?
    (draft? || status_was == 'draft') && Current.organization == organization
  end

  private

    def check_if_can_be_modified
      throw :abort unless can_be_modified?
    end
end
