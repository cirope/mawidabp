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
    validate :validate_manual_scores
  end

  private

    def validate_manual_scores
      scores = manual_scores.first.last

      if scores.values.count != scores.values.uniq.count
        errors.add :base, :invalid, message: 'No se pueden repetir valores'
      end

      current_scores.each do |score, value|
        if value.to_s !~ /\A\d+\Z/i
          errors.add :base, message: "El valor de '#{score}' no es válido"
        elsif value.to_i < 0 || value.to_i > 100
          errors.add :base, message: "El valor de '#{score}' debe estar entre 0 y 100"
        end
      end
    end
end
