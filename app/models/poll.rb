class Poll < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  # Validaciones
  validates :questionnaire_id, :user_id, :presence => true
  validates_length_of :comments, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :questionnaire
  belongs_to :user
  belongs_to :pollable, :polymorphic => true
  has_many :answers, :include => :question, :dependent => :destroy, :order => "#{Question.table_name}.sort_order ASC"
  # Callbacks
  after_create :send_poll_email
  before_validation(:on => :update) do
    self.answered = true
  end

  accepts_nested_attributes_for :answers

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    if self.questionnaire && self.answers.empty?
      self.questionnaire.questions.each do |question|
        self.answers.build(:question => question)
      end
    end
  end

  def send_poll_email
    Notifier.pending_poll_email(self.user).deliver
  end

end
