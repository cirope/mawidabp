module VersionsHelper
  def show_whodunnit(whodunnit)
    whodunnit ? User.find(whodunnit).full_name_with_user : '-'
  end

  def extract_version_changes(version)
    changes = []
    old_attributes = version.reify.try(:attributes) || {}
    new_attributes = (version.next.try(:reify) || version.item.reload).attributes
    item_class = version.item.class

    old_attributes.each do |attribute, old_value|
      new_value = new_attributes.delete attribute

      if old_value != new_value
        changes << {
          :attribute => item_class.human_attribute_name(attribute),
          :old_value => old_value,
          :new_value => new_value
        }
      end
    end

    new_attributes.each do |attribute, new_value|
      changes << {
        :attribute => item_class.human_attribute_name(attribute),
        :old_value => '-',
        :new_value => new_value
      }
    end

    changes
  end
end