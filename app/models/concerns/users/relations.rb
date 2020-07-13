module Users::Relations
  extend ActiveSupport::Concern

  included do
    has_many :related_user_relations, dependent: :destroy
    has_many :related_users, through: :related_user_relations
    has_many :business_unit_type_users, dependent: :destroy
    has_many :business_unit_types, through: :business_unit_type_users

    accepts_nested_attributes_for :related_user_relations, allow_destroy: true,
      reject_if: ->(attributes) { attributes['related_user_id'].blank? }
    accepts_nested_attributes_for :business_unit_type_users, allow_destroy: true,
      reject_if: ->(attributes) { attributes['business_unit_type_id'].blank? }
  end

  def related_users_and_descendants
    related_users + related_users.map(&:descendants).flatten.uniq
  end
end
