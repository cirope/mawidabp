module Organizations::Group
  extend ActiveSupport::Concern

  included do
    attr_readonly :group_id

    before_save :set_group, on: :create

    belongs_to :group
  end

  private

  def set_group
    if Organization.exists? Organization.current_id
      self.group_id = Organization.find(Organization.current_id).group_id
    end
  end
end
