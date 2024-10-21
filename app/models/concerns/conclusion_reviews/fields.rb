module ConclusionReviews::Fields
  extend ActiveSupport::Concern

  included do
    serialize :fields, JSON unless POSTGRESQL_ADAPTER
  end

  def work_scope
    fields&.fetch('work_scope', nil)
  end

  def work_scope=(value)
    assign_field('work_scope', value)
  end

  private

    def assign_field(name, value)
      self.fields ||= {}
      prev_value = self.fields[name]

      fields_will_change! unless prev_value == value
      self.fields[name] = value
    end
end
