PaperTrail.config.track_associations = false
PaperTrail.serializer = PaperTrail::Serializers::JSON

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

# Oracle (or PaperTrail with oracle) put serialized attributes within a hash
# with a single entry with a 'value' key
# Visit https://github.com/airblade/paper_trail/blob/master/lib/paper_trail/attribute_serializers/cast_attribute_serializer.rb
if ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
  module PaperTrail
    module AttributeSerializers
      class CastAttributeSerializer
        def deserialize(attr, val)
          if defined_enums[attr] && val.is_a?(::String)
            val
          else
            val = val.kind_of?(Hash) ? val['value'] || val : val

            @klass.type_for_attribute(attr).deserialize(val)
          end
        end
      end
    end
  end
end
