module Organizations::Group
  extend ActiveSupport::Concern

  included do
    before_create :set_group

    belongs_to :group, optional: true
  end

  private

  def set_group
    if Organization.exists? Current.organization&.id
      self.group_id = Current.organization.group_id
    end
  end
end
