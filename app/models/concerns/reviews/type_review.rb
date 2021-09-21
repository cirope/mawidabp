module Reviews::TypeReview
  extend ActiveSupport::Concern

  TYPES_REVIEW = {
    operational_audit: 1,
    system_audit: 2
  }
end
