class Answer < ApplicationRecord
  include Auditable
  include Answers::Validations

  belongs_to :question, optional: true
  belongs_to :poll, optional: true
  belongs_to :answer_option, optional: true
end
