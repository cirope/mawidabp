module ResourceUtilizations::Validation
  extend ActiveSupport::Concern

  included do
    validates :units, :resource, :resource_type, presence: true
    validates :units, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 9_999_999_999_999.99
    }, allow_nil: true, allow_blank: true

    after_validation :check_maximum_hours_for_task_of_human_resources
  end

  def check_maximum_hours_for_task_of_human_resources
    if self.resource_consumer
      start_date                        = self.resource_consumer.start
      end_date                          = self.resource_consumer.end
      days                              = work_days(start_date, end_date).count
      hours_for_days                    = work_hours_per_day
      maximum_hours_for_human_resources = days * hours_for_days

      if self.units > (maximum_hours_for_human_resources) && human_resources
        self.errors.add :units, :less_than_or_equal_to, count: maximum_hours_for_human_resources

        throw :abort
      else
        true
      end
    end
  end

  def human_resources
    self.resource_consumer_type == 'WorkflowItem' &&
      self.resource_type == 'User'
  end


  def work_days start_date, end_date
    if start_date && end_date
      (start_date.to_date..end_date.to_date).select &:workday?
    else
      []
    end
  end

  def work_hours_per_day
    setting = Current.organization.settings.find_by name: 'hours_of_work_per_day'
    value   = setting&.value.to_f

    value > 0 ? value : 8
  end
end
