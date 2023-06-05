# frozen_string_literal: true

class NbcInternalControlQualificationAsGroupOfCompaniesForm < NbcAnnualReportForm
  property :previous_period_id
  property :organizations
  property :periods

  validates :previous_period_id, presence: true
  validate :previous_period_must_be_before_period
  validate :organization_units_must_have_same_name
  validate :periods_must_be_the_same

  def previous_period
    Period.list.find_by_id previous_period_id
  end

  private

    def previous_period_must_be_before_period
      if self.previous_period && self.period && self.previous_period.start >= self.period.start
        errors.add :previous_period_id, :must_be_before_period
      end
    end

    def organization_units_must_have_same_name
      organization_ids = Organization.where(prefix: ORGANIZATIONS_WITH_INTERNAL_CONTROL_QUALIFICATION_REPORT).pluck(:id)

      business_unit_types_per_organization = BusinessUnitType
        .where(organization_id: organization_ids)
        .group(:organization_id)
        .pluck(:organization_id, Arel.sql("array_agg(name ORDER BY name)"))
        .to_h

      first_organization = business_unit_types_per_organization.values.first

      unless business_unit_types_per_organization.values.all? { |names| names == first_organization } &&
        business_unit_types_per_organization.keys.length == organization_ids.length
          different_names = find_different_names(business_unit_types_per_organization)

          errors.add :organizations, :must_have_the_same_business_unit_type_names,
            different_names: different_names.to_sentence, count: different_names.count
      end
    end

    def periods_must_be_the_same
      organization_ids = Organization.where(prefix: ORGANIZATIONS_WITH_INTERNAL_CONTROL_QUALIFICATION_REPORT).pluck(:id)

      periods_per_organization = Period
        .where(organization_id: organization_ids)
        .group(:organization_id)
        .pluck(:organization_id, Arel.sql("array_agg(name ORDER BY name)"))
        .to_h

      first_period = periods_per_organization.values.first

      unless periods_per_organization.values.all? { |names| names == first_period } &&
        periods_per_organization.keys.length == organization_ids.length
          different_names = find_different_names(periods_per_organization)

          errors.add :periods, :must_have_the_same_names,
            different_names: different_names.to_sentence, count: different_names.count
      end
    end

    def find_different_names(names_per_organization)
      different_names    = []
      first_organization = names_per_organization.values.first

      names_per_organization.each do |organization_id, names|
        different_names << names - first_organization
      end

      different_names.flatten.uniq
    end

end
