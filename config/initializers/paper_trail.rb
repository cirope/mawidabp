module PaperTrail::VersionConcern
  def changes_until other
    new_attributes = (other.try(:reify, has_one: false) || item).try(:attributes) || {}

    changes = old_attributes.map do |attribute, old_value|
      new_value = new_attributes.delete attribute

      change_for attribute, old_value, new_value unless old_value == new_value
    end

    changes.compact + new_attributes.map { |attr, value| change_for attr, '-', value }
  end

  def changes_from_next
    changes_until self.next
  end

  private

    def old_attributes
      reify(has_one: false).try(:attributes) || {}
    end

    def item_class
      self.try(:class) || item.try(:class)
    end

    def change_for attribute, old_value, new_value
      HashWithIndifferentAccess.new(
        attribute: item_class.human_attribute_name(attribute),
        old_value: old_value.to_translated_string.split_if_no_space_in(50),
        new_value: new_value.to_translated_string.split_if_no_space_in(50)
      ) if old_value.present? || new_value.present?
    end
end
