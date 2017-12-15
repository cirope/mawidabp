module Reviews::BestPracticeComments
  extend ActiveSupport::Concern

  included do
    before_save :clean_stale_best_practice_comments

    has_many :best_practice_comments, dependent: :destroy

    accepts_nested_attributes_for :best_practice_comments, allow_destroy: true
  end

  def build_best_practice_comments
    grouped_control_objective_items_by_best_practice.each do |best_practice, _cois|
      exists = best_practice_comments.any? do |pcc|
        pcc.best_practice_id == best_practice.id
      end

      unless exists
        best_practice_comments.build best_practice_id: best_practice.id
      end
    end
  end

  private

    def clean_stale_best_practice_comments
      best_practice_ids = best_practices.ids

      best_practice_comments.each do |pcc|
        if best_practice_ids.exclude? pcc.best_practice_id
          pcc.mark_for_destruction
        end
      end
    end
end
