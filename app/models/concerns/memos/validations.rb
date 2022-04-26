module Memos::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :close_date, presence: true
    validates :required_by, inclusion: { in: Memo::REQUIRED_BY_OPTIONS },
                            if: :required_by_present?
    validate :has_file_model_memos
    validate :plan_item_is_not_used
    validate :cant_change_fields
  end

  private

    def has_file_model_memos
      if file_model_memos.reject(&:marked_for_destruction?).blank?
        errors.add(:base, :file_model_memos_blank)
      end
    end

    def plan_item_is_not_used
      errors.add(:plan_item_id, :used) if plan_item.present? && plan_item_used?
    end

    def plan_item_used?
      Review.exists?(plan_item_id: plan_item.id) || plan_item_used_by_memo?
    end

    def plan_item_used_by_memo?
      if new_record?
        Memo.exists?(plan_item_id: plan_item.id)
      else
        Memo.where.not(id: id).exists?(plan_item_id: plan_item.id)
      end
    end

    def cant_change_fields
      errors.add(:base, :cant_change_fields) if readonly_fields? && change_any_field?
    end

    def change_any_field?
      changed? || file_model_memos_changed?
    end

    def file_model_memos_changed?
      file_model_memos.any? do |fm_m|
        fm_m.file_model.changed? || fm_m.new_record? || fm_m.marked_for_destruction? 
      end
    end

    def required_by_present?
      Memo::REQUIRED_BY_OPTIONS.present?
    end
end
