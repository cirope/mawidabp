module Organizations::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :prefix, :logo_style, pdf_encoding: true, presence: true,
      length: { maximum: 255 }
    validates :description, pdf_encoding: true
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }
    validates :logo_style, inclusion: {
      in: %w(default success info warning danger)
    }
    validates :prefix,
      format: { with: /\A[A-Za-z0-9][A-Za-z0-9\-]+\z/ },
      uniqueness: { case_sensitive: false },
      exclusion: { in: APP_ADMIN_PREFIXES }
    validate :validate_options
  end

  private

    def validate_options
      options = options_by(option_type).to_a

      if options.present?
        last_option     = options.first.last
        current_options = current_options_by option_type

        if last_option == options[1]&.last
          errors.add :base, option_type.to_sym, message: I18n.t('options.scores.errors.score_not_change')
        elsif current_options.blank?
          errors.add :base, option_type.to_sym, message: I18n.t('options.scores.errors.blank')
        else
          repeated = []

          current_options.each do |option, value|
            if value.to_i < 0 || value.to_i > 100
              errors.add :base, option_type.to_sym, message: I18n.t('options.scores.errors.numericality', value: option)
            elsif value.to_s !~ /\A\d+\Z/i
              errors.add :base, option_type.to_sym, message: I18n.t('options.scores.errors.invalid', value: option)
            elsif repeated.include? value
              errors.add :base, option_type.to_sym, message: I18n.t('options.scores.errors.taken', value: option)
            elsif option.blank?
              errors.add :base, option_type.to_sym, message: I18n.t('options.scores.errors.blank')
            end

            repeated << value
          end
        end
      end
    end
end
