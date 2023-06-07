# frozen_string_literal: true

class NbcInternalControlQualificationAsGroupOfCompaniesForm < NbcAnnualReportForm
  property :previous_period_id
  property :business_unit_types
  property :periods

  validates :previous_period_id, presence: true
  validate :previous_period_must_be_before_period
  validate :business_unit_types_must_have_the_same_name
  validate :periods_must_have_the_same_name

  def previous_period
    Period.list.find_by_id previous_period_id
  end

  def business_unit_type_names
    business_unit_types.present? ? business_unit_types : BusinessUnitType.list.map(&:name)
  end

  def period_names
    periods.present? ? periods : Period.list.map(&:name)
  end

  private

    def organization_ids
      Organization.where(prefix: ORGANIZATIONS_WITH_INTERNAL_CONTROL_QUALIFICATION_REPORT).pluck(:id)
    end

    def previous_period_must_be_before_period
      if self.previous_period && self.period && self.previous_period.start >= self.period.start
        errors.add :previous_period_id, :must_be_before_period
      end
    end

    def business_unit_types_must_have_the_same_name
      validate_same_names(:business_unit_types, self.business_unit_type_names, :must_have_the_same_business_unit_type_names)
    end

    def periods_must_have_the_same_name
      validate_same_names(:periods, self.period_names, :must_have_the_same_names)
    end

    def validate_same_names(association, current_names, error_key)
      organization_ids = self.organization_ids

      items_per_organization = association.to_s.classify.constantize
        .where(organization_id: organization_ids)
        .group(:organization_id)
        .pluck(:organization_id, Arel.sql("array_agg(name ORDER BY name)"))
        .to_h

      unless items_per_organization.values.all? { |names| names.sort == current_names.sort } &&
        items_per_organization.keys.length == organization_ids.length
          different_names = find_different_names(items_per_organization, current_names)

          errors.add association, error_key,
            different_names: different_names.to_sentence, count: different_names.count
      end
    end

    def find_different_names(names_per_organization, current_names)
      different_names = []

      names_per_organization.each do |organization_id, names|
        different_names << ((names - current_names) | (current_names - names))
      end

      different_names.flatten.uniq
    end
end
