module Findings::Commitments
  extend ActiveSupport::Concern

  included do
    serialize :commitments, JSON unless POSTGRESQL_ADAPTER

    before_save :register_commitment, if: :register_commitment?
  end

  def calculate_commitments
    commitments       = repeated_of&.calculate_commitments || {}
    last_checked_date = nil

    follow_up_dates_to_check_against.each do |date|
      if last_checked_date.blank? || date < last_checked_date
        commitment_level = endorsed_commitment_for date

        if commitment_level
          commitments[commitment_level.to_s] ||= []
          commitments[commitment_level.to_s] << date
        end

        last_checked_date = date
      end
    end

    commitments
  end

  private

    def register_commitment?
      Finding.show_commitment_support? &&
        (unmark_rescheduled? || calculate_reschedule_count?)
    end

    def register_commitment
      if unmark_rescheduled?
        self.commitments = nil
      elsif calculate_reschedule_count?
        self.commitments = calculate_commitments
      end
    end

    def endorsed_commitment_for date
      fa = finding_answers.where(commitment_date: date).take

      if date && fa&.endorsements&.any? && fa.endorsements.all?(&:approved?)
        commitment_date_required_level date
      end
    end
end
