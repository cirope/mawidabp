module Memos::Validations
  extend ActiveSupport::Concern

  included do
    before_save :set_required_by

    validates :name, :close_date, presence: true
    validates :required_by_text, presence: true, if: :manual_required_by?
    validates :required_by, inclusion: { in: Memo::REQUIRED_BY_OPTIONS },
                            if: :not_manual_required_by?
    validate :has_files
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
      ['1', true].include? manual_required_by
    end

    def has_files
      if files_attachments.all?(&:marked_for_destruction?) &&
         files.blobs.detect(&:new_record?).blank?
        errors.add(:base, :files_blank)
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
      changed? || files_changed?
    end

    def files_changed?
      files.any? { |f| f.marked_for_destruction? || f.changed? }
    end
end
