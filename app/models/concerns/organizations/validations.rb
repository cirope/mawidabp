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
    validate :validate_scores
  end

  private

    def validate_scores
      scores = scores_by(score_type).to_a

      if scores.present?
        last_score    = scores.first.last
        current_score = current_scores_by score_type

        if last_score == scores[1]&.last
          errors.add :base, score_type.to_sym, message: I18n.t('options.scores.errors.score_not_change')
        elsif current_score.blank?
          errors.add :base, score_type.to_sym, message: I18n.t('options.scores.errors.blank')
        else
          repeated = []

          current_score.each do |score, value|
            if value.to_i < 0 || value.to_i > 100
              errors.add :base, score_type.to_sym, message: I18n.t('options.scores.errors.numericality', value: score)
            elsif value.to_s !~ /\A\d+\Z/i
              errors.add :base, score_type.to_sym, message: I18n.t('options.scores.errors.invalid', value: score)
            elsif repeated.include? value
              errors.add :base, score_type.to_sym, message: I18n.t('options.scores.errors.taken', value: score)
            elsif score.blank?
              errors.add :base, score_type.to_sym, message: I18n.t('options.scores.errors.blank')
            end

            repeated << value
          end
        end
      end
    end
end
