module ResourceUtilizations::Validation
  extend ActiveSupport::Concern

  included do
    validates :units, :resource, :resource_type, presence: true
    validates :units, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 9_999_999_999_999.99
    }, allow_nil: true, allow_blank: true

    validate :check_maximum_hours_for_task_of_human_resources
  end

  def check_maximum_hours_for_task_of_human_resources
    if self.resource_consumer
      start_date                        = self.resource_consumer.start
      end_date                          = self.resource_consumer.end
      days                              = work_days(start_date, end_date).count
      hours_for_days                    = work_hours_per_day
      maximum_hours_for_human_resources = (days * hours_for_days) - workflow_items_overladed

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

  def workflow_items_overladed
    workflow_items = WorkflowItem.where(workflow_id: self.resource_consumer.workflow_id).
      where.not(id: resource_consumer.id)

    start_date = resource_consumer.start
    end_date   = resource_consumer.end
    days_overloaded = 0
    hours_overloaded = 0
    hours_available = 0

    workflow_items.map do |wi|
      wi.human_resource_utilizations.each do |resource_utilization|
        if resource_utilization.resource_id == resource_id && overloaded_date(wi.start, wi.end)
          units_used = resource_utilization.units
          days = work_days(wi.start, wi.end).count
          hours_for_days                    = work_hours_per_day
          maximum_hours = (days * hours_for_days) - units_used

          if start_date >= wi.start && end_date > wi.end
            days_overloaded += work_days(start_date, wi.end).size
            hours_overloaded = (days_overloaded * hours_for_days)
          end

          if start_date < wi.start && end_date <= wi.end
            days_overloaded = work_days(wi.start, end_date).size
          end

          if start_date >= wi.start && end_date <= wi.end
            days_overloaded += (work_days(wi.start, wi.end) - work_days(start_date, end_date)).size
          end

          if maximum_hours > hours_overloaded
            hours_available = hours_overloaded
          else
            hours_available = hours_overloaded - maximum_hours
          end
        end
      end
    end

    hours_available
  end

  def overloaded_date  wi_start_date, wi_end_date
    (resource_consumer.start.between?(wi_start_date, wi_end_date) ||
     resource_consumer.end.between?(wi_start_date, wi_end_date))
  end
end
