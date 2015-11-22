module Users::Relations
  extend ActiveSupport::Concern

  included do
    has_many :related_user_relations, dependent: :destroy
    has_many :related_users, through: :related_user_relations

    accepts_nested_attributes_for :related_user_relations, allow_destroy: true,
      reject_if: ->(attributes) { attributes['related_user_id'].blank? }
  end

  def related_users_and_descendants
    related_users + related_users.map(&:descendants).flatten.uniq
  end
end
