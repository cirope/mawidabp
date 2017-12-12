module Reviews::ProcessControlComments
  extend ActiveSupport::Concern

  included do
    before_save :clean_stale_process_control_comments

    has_many :process_control_comments, dependent: :destroy

    accepts_nested_attributes_for :process_control_comments, allow_destroy: true
  end

  def build_process_control_comments
    grouped_control_objective_items.each do |process_control, _cois|
      exists = process_control_comments.any? do |pcc|
        pcc.process_control_id == process_control.id
      end

      unless exists
        process_control_comments.build process_control_id: process_control.id
      end
    end
  end

  private

    def clean_stale_process_control_comments
      process_control_ids = process_controls.ids

      process_control_comments.each do |pcc|
        if process_control_ids.exclude? pcc.process_control_id
          pcc.mark_for_destruction
        end
      end
    end
end
