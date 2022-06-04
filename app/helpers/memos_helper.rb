module MemosHelper
  def memo_plan_item_field form
    require 'ostruct' unless defined? OpenStruct

    grouped_plan_items = PlanItem.list_unused(@memo.period_id)
                                 .group_by(&:business_unit_type)

    business_unit_types = grouped_plan_items.map do |but, plan_items|
      sorted_plan_items = plan_items.sort_by(&:project)

      OpenStruct.new name: but.name, plan_items: sorted_plan_items
    end

    form.grouped_collection_select :plan_item_id, business_unit_types,
                                   :plan_items, :name, :id, :project_with_dates,
                                   { prompt: true },
                                   { class: 'form-control', disabled: false }
  end

  def show_file_model_memos memo
    out = '<ul>'

    memo.file_model_memos.each do |fm_m|
      link_for_download_attachment = link_to(
        fm_m.file_model.file_file_name, fm_m.file_model.file.url
      )

      out << "<li>#{link_for_download_attachment}</li>"
    end

    out << '</ul>'

    raw out
  end

  def required_by_options
    Memo::REQUIRED_BY_OPTIONS.map do |option|
      [option, option]
    end
  end

  def manual_required_by_checked required_by
    required_by.present? ? Memo::REQUIRED_BY_OPTIONS.exclude?(required_by) : false
  end

  def required_by_text_value required_by
    Memo::REQUIRED_BY_OPTIONS.exclude?(required_by) ? required_by : ''
  end
end
