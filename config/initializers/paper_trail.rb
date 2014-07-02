module PaperTrail::VersionConcern
  def changes_until other
    changes        = []
    old_attributes = reify(has_one: false).try(:attributes) || {}
    new_attributes = (other.try(:reify, has_one: false) || item).try(:attributes) || {}
    item_class     = self.try(:class) || item.try(:class)

    old_attributes.each do |attribute, old_value|
      new_value = new_attributes.delete attribute

      if old_value != new_value && !(old_value.blank? && new_value.blank?)
        changes << HashWithIndifferentAccess.new(
          attribute: item_class.human_attribute_name(attribute),
          old_value: old_value.to_translated_string.split_if_no_space_in(50),
          new_value: new_value.to_translated_string.split_if_no_space_in(50)
        )
      end
    end

    new_attributes.each do |attribute, new_value|
      changes << HashWithIndifferentAccess.new(
        attribute: item_class.human_attribute_name(attribute),
        old_value: '-',
        new_value: new_value
      )
    end

    changes
  end

  def changes_from_next
    changes_until self.next
  end
end
