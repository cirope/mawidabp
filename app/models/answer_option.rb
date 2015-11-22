class AnswerOption < ActiveRecord::Base
  include Associations::DestroyPaperTrail
  include Auditable

  validates :option, presence: true
  validates :option, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true

  belongs_to :question

  def to_s
    option
  end
end
