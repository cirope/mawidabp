module BestPractices::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :organization_id, presence: true
    validates :name, length: { maximum: 255 }, allow_nil: true, allow_blank: true
    validates :organization_id, numericality: { only_integer: true },
      allow_blank: true, allow_nil: true
    validates :name, uniqueness: { case_sensitive: false, scope: :organization_id }
    validates_each :process_controls do |record, attr, value|
      unless value.all? {|pc| !pc.marked_for_destruction? || pc.can_be_destroyed?}
        record.errors.add attr, :locked
      end
    end
  end
end
