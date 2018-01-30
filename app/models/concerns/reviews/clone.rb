module Reviews::Clone
  extend ActiveSupport::Concern

  def clone_from other
    self.attributes = other.attributes.merge(
      'id'             => nil,
      'period_id'      => nil,
      'plan_item_id'   => nil,
      'identification' => nil,
      'file_model_id'  => nil
    )

    copy_control_objective_items_from other
    copy_review_user_assignments_from other
  end

  private

    def copy_control_objective_items_from other
      other.control_objective_items.order(:order_number).each do |coi|
        coi_attributes = coi.attributes.merge(
          'id'                 => nil,
          'review_id'          => self.id,
          'control_attributes' => coi.control.attributes.merge('id' => nil)
        )

        control_objective_items.build coi_attributes
      end
    end

    def copy_review_user_assignments_from other
      other.review_user_assignments.each do |rua|
        review_user_assignments.build rua.attributes.merge('id' => nil)
      end
    end
end
