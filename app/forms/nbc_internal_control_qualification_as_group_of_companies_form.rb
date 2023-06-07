# frozen_string_literal: true

class NbcInternalControlQualificationAsGroupOfCompaniesForm < NbcAnnualReportForm
  property :previous_period_id
  property :business_unit_types
  property :organizations

  validates :previous_period_id, presence: true
  validate :previous_period_must_be_before_period
  validate :business_unit_types_must_have_the_same_name
  validate :period_must_have_the_same_name
  validate :previous_period_must_have_the_same_name
  validate :organizations_must_be_configured

  def previous_period
    Period.list.find_by_id previous_period_id
  end

  def business_unit_type_names
    business_unit_types.presence || BusinessUnitType.list.map(&:name)
  end

  private

    def organization_ids
      Organization.where(prefix: ORGANIZATIONS_WITH_INTERNAL_CONTROL_QUALIFICATION_REPORT).pluck(:id)
    end

    def organizations_must_be_configured
      unless organization_ids.present? &&
        ORGANIZATIONS_WITH_INTERNAL_CONTROL_QUALIFICATION_REPORT.count == organization_ids.count
          errors.add :organizations, :are_misconfigured
      end
    end

    def previous_period_must_be_before_period
      if self.previous_period && self.period && self.previous_period.start >= self.period.start
        errors.add :previous_period_id, :must_be_before_period
      end
    end

    def period_must_have_the_same_name
      validate_same_period_name(:period_id, self.period.name) if self.period
    end

    def previous_period_must_have_the_same_name
      validate_same_period_name(:previous_period_id, self.previous_period.name) if self.previous_period
    end

    def validate_same_period_name association, period_name
      organization_ids = self.organization_ids

      valid_organizations = Period
        .where(organization_id: organization_ids, name: period_name)
        .pluck(:organization_id)
        .uniq

      if valid_organizations.length != organization_ids.length
        buggy_organizations       = organization_ids - valid_organizations
        buggy_organizations_names = Organization.find(buggy_organizations).pluck(:name)

        errors.add association, :must_have_the_same_name, organizations: buggy_organizations_names.to_sentence
      end
    end

    def business_unit_types_must_have_the_same_name
      organization_ids = self.organization_ids
      current_names = self.business_unit_type_names

      but_per_organization = BusinessUnitType
        .where(organization_id: organization_ids)
        .group(:organization_id)
        .pluck(:organization_id, Arel.sql("array_agg(name ORDER BY name)"))
        .to_h

      unless but_per_organization.values.all? { |names| names.sort == current_names.sort } &&
        but_per_organization.keys.length == organization_ids.length
          different_names = find_different_names but_per_organization, current_names

          errors.add :business_unit_types, :must_have_the_same_business_unit_type_names,
            different_names: different_names.to_sentence, count: different_names.count
      end
    end

    def find_different_names names_per_organization, current_names
      different_names = []

      names_per_organization.each do |organization_id, names|
        different_names << ((names - current_names) | (current_names - names))
      end

      different_names.flatten.uniq
    end
end
