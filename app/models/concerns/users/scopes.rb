# frozen_string_literal: true

module Users::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      includes(:organizations).
        where(organizations: { id: Current.organization&.id }).
        references :organizations
    }
    scope :group_list, -> {
      includes(:group).
        where(groups: { id: Current.group&.id }).
        references :groups
    }
    scope :without_organization, -> {
      includes(:organizations).
        where(organizations: { id: nil }).
        references :organizations
    }
    scope :not_hidden, -> { where hidden: false }
    scope :enabled, -> { where enable: true }
    scope :managers, -> {
      includes(organization_roles: :role).where(
        roles: {
          role_type: ::Role::TYPES[:manager]
        }
      )
    }
    scope :auditors, -> {
      includes(organization_roles: :role).where(
        roles: {
          role_type: ::Role::TYPES[:auditor]
        }
      )
    }
    scope :auditors_and_act_as_audited, -> {
      includes(organization_roles: :role).where(
        roles: {
          role_type: [::Role::TYPES[:auditor], ::Role::ACT_AS[:audited]].flatten
        }
      )
    }
    scope :include_tags, -> {
      includes('tags').references('tags')
    }
  end

  def recovery?
    tags.with_option('recovery', '1').exists?
  end

  def update_saml_request_id new_request_id
    update_column :saml_request_id, new_request_id
  end

  module ClassMethods
    def by_email email
      where(
        "LOWER(#{quoted_table_name}.#{qcn 'email'}) = ?", email&.downcase
      ).take
    end

    def by_user user
      where(
        "LOWER(#{quoted_table_name}.#{qcn 'user'}) = ?", user&.downcase
      ).take
    end

    def all_with_findings_for_notification
      includes(finding_user_assignments: :raw_finding).
        where(findings: { state: Finding::STATUS[:notify], final: false }).
        order(
          [
            "#{quoted_table_name}.#{qcn('last_name')} ASC",
            "#{quoted_table_name}.#{qcn('name')} ASC"
          ].map { |o| Arel.sql o }
        ).
        references(:findings)
    end

    def all_with_conclusion_final_reviews_for_notification
      joins = { review_user_assignments: { review: :conclusion_final_review } }
      ids   = distinct.
                left_joins(joins).
                merge(ReviewUserAssignment.audit_team).
                merge(ConclusionFinalReview.with_near_close_date).
                ids

      where(id: ids) # TODO: remove when we don't have to _support_ Oracle
    end

    def list_all_with_pending_findings
      left_joins(finding_user_assignments: :raw_finding).
        where(findings: { final: false }).
        merge(Finding.with_pending_status).
        merge(Finding.list).
        references(:findings).
        distinct.
        select(column_names - ['notes'])
    end

    def list_with_corporate
      conditions   = [
        "#{organizations_table}.#{Organization.qcn('id')} = :organization_id",
        [
          "#{organizations_table}.#{Organization.qcn('group_id')} = :group_id",
          "#{organizations_table}.#{Organization.qcn('corporate')} = :true"
        ].join(' AND ')
      ].map { |c| "(#{c})" }.join(' OR ')

      joins(:organizations).
        where(conditions, corporate_list_parameters).
        references(:organizations).
        distinct.
        select(column_names - ['notes'])
    end

    def find_user data
      User.group_list.by_email(data[:email])             ||
        User.without_organization.by_email(data[:email]) ||
        User.list.by_user(data[:user])
    end

    private

      def organizations_table
        Organization.quoted_table_name
      end

      def corporate_list_parameters
        {
          organization_id: Current.organization&.id,
          group_id:        Current.group&.id,
          true:            true
        }
      end
  end
end
