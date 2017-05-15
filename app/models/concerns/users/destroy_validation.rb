module Users::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def disable
    update_column :enable, false if has_not_orphan_fingings?
  end

  private

    def has_not_orphan_fingings?
      if has_pending_findings?
        errors.add :base, I18n.t('user.will_be_orphan_findings')

        false
      else
        true
      end
    end

    def check_if_can_be_destroyed
      throw :abort unless has_not_orphan_fingings?
    end
end
