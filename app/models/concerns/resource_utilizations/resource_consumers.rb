module ResourceUtilizations::ResourceConsumers
  extend ActiveSupport::Concern

  included do
    belongs_to :resource_consumer, polymorphic: true

    belongs_to :workflow_item, -> {
      joins(:resource_utilizations).where resource_utilizations: { resource_consumer_type: 'WorkflowItem' }
    }, foreign_key: 'resource_consumer_id'

    belongs_to :plan_item, -> {
      joins(:resource_utilizations).where resource_utilizations: { resource_consumer_type: 'PlanItem' }
    }, foreign_key: 'resource_consumer_id'

    has_one :workflow, -> {
      joins workflow_items: :resource_utilizations
    }, through: :workflow_item

    has_one :review, -> {
      joins workflow: { workflow_items: :resource_utilizations }
    }, through: :workflow

    has_one :planed_review, -> {
      joins plan_item: :resource_utilizations
    }, through: :plan_item, source: :review, class_name: 'Review'
  end
end
