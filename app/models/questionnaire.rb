class Questionnaire < ActiveRecord::Base

  has_paper_trail meta: { organization_id: ->(obj) { Organization.current_id } }

  # Constantes
  POLLABLE_TYPES = [
    'ConclusionReview'
  ]

  # Validaciones
  validates :name, :organization_id, :email_subject, :email_text, :email_link,
    :presence => true
  validates_uniqueness_of :name, :allow_nil => true, :allow_blank => true
  validates_length_of :name, :email_subject, :email_text, :email_link,
    :email_clarification, :maximum => 255, :allow_nil => true, :allow_blank => true
  # Relaciones
  belongs_to :organization
  has_many :polls, :dependent => :destroy
  has_many :questions, -> { order("#{Question.table_name}.sort_order ASC") },
    :dependent => :destroy

  # Named scopes
  scope :list, -> { where(organization_id: Organization.current_id) }
  scope :by_pollable_type, ->(type) { where(:pollable_type => type) }
  scope :pollable, -> { where('pollable_type IS NOT NULL') }
  scope :by_organization, ->(org_id, id) {
    unscoped.where('id = :id AND organization_id = :org_id', :org_id => org_id, :id => id)
  }

  accepts_nested_attributes_for :questions, :allow_destroy => true

  def total_polls(answered = true)
    total = 0
    self.polls.each do |poll|
      total += 1 if poll.answered == answered
    end

    total
  end

  def answer_rates(polls)
    rates = ActiveSupport::OrderedHash.new
    self.questions.each do |question|
      rates[question.question] ||= []
      Question::ANSWER_OPTIONS.each do
        rates[question.question] << 0
      end
    end

    answered = 0
    unanswered = 0
    polls.each do |poll|
      if poll.answered
        answered += 1
        poll.answers.each do |answer|
          # Si es múltiple opción
          if answer.answer_option
            option = Question::ANSWER_OPTIONS.rindex answer.answer_option.option.to_sym
            rates[answer.question.question][option] += 1
          end
        end
      else
        unanswered +=1
      end
    end

    self.questions.each do |question|
      question = question.question
      Question::ANSWER_OPTIONS.each_index do |i|
        unless answered == 0
          rates[question][i] = ((rates[question][i] / answered.to_f) * 100).round 2
        else
          rates[question][i] = 0
        end
      end
    end

    return rates, answered, unanswered
  end
end
