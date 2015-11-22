class Answer < ActiveRecord::Base
  include Associations::DestroyPaperTrail
  include Auditable
  include Answers::Validations

  belongs_to :question
  belongs_to :poll
  belongs_to :answer_option
end
