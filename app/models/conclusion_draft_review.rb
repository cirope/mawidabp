class ConclusionDraftReview < ConclusionReview
  # Callbacks
  before_save :check_for_approval

  # Atributos de sólo lectura
  attr_accessor :force_approval

  # Restricciones
  validates_uniqueness_of :review_id, :allow_blank => true, :allow_nil => true

  def check_for_approval
    self.approved = self.review && (self.review.is_approved? ||
        (self.force_approval? && self.review.can_be_approved_by_force)) &&
      (self.notifications_approved? || self.force_approval?)

    true
  end

  def force_approval?
    self.force_approval == true || self.force_approval == '1'
  end
end