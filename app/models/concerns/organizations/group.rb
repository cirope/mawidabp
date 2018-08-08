module Organizations::Group
  extend ActiveSupport::Concern

  included do
    attr_readonly :group_id

    before_save :set_group, on: :create

    belongs_to :group, optional: true
  end

  private

  def set_group
    if Organization.exists? Current.organization&.id
      self.group_id = Current.organization.group_id
    end
  end
end
