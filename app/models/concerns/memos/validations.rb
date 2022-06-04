module Memos::Validations
  extend ActiveSupport::Concern

  included do
    before_validation :set_required_by

    validates :name, :close_date, :required_by, presence: true
    validates :required_by, inclusion: { in: Memo::REQUIRED_BY_OPTIONS },
                            if: :not_manual_required_by?
    validate :has_file_model_memos
    validate :plan_item_is_not_used
    validate :cant_change_fields
  end

  private

    def set_required_by
      self.required_by = required_by_text if manual_required_by?
    end

    def not_manual_required_by?
      !manual_required_by?
    end

    def manual_required_by?
      manual_required_by == '1'
    end

    def has_file_model_memos
      if file_model_memos.reject(&:marked_for_destruction?).blank?
        errors.add(:base, :file_model_memos_blank)
      end
    end

    def plan_item_is_not_used
      errors.add(:plan_item_id, :used) if plan_item.present? && plan_item_used?
    end

    def plan_item_used?
      Review.list.exists?(plan_item_id: plan_item.id) || plan_item_used_by_memo?
    end

    def plan_item_used_by_memo?
      if new_record?
        Memo.list.exists?(plan_item_id: plan_item.id)
      else
        Memo.list.where.not(id: id).exists?(plan_item_id: plan_item.id)
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
end
