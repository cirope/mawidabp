module Findings::XML
  extend ActiveSupport::Concern

  def to_xml options = {}
    default_options = { skip_types: true, only: [:solution_date] }

    super default_options.merge(options) do |xml|
      xml_finding_tags xml

      if finding_user_assignments.empty?
        xml.tag! 'users' # empty tag
      else
        xml.users { xml_finding_users_tags xml }
      end

      yield xml if block_given?
    end
  end

  private

    def xml_finding_tags xml
      # Para mantener siempre el mismo orden (ocurrencias ajenas)
      xml.tag! 'origination-date', origination_date
      xml.tag! 'id',               id
      xml.tag! 'follow-up-date',   follow_up_date
      xml.tag! 'description',      description
      xml.tag! 'review-code',      review_code
      xml.tag! 'title',            title
      xml.tag! 'answer',           answer
      xml.tag! 'risk-text',        (risk_text if respond_to?(:risk_text))
      xml.tag! 'state-text',       state_text
      xml.tag! 'review-text',      review_text
    end

    def xml_finding_users_tags xml
      finding_user_assignments.each do |fua|
        xml.user do
          xml.tag! 'name',          fua.user.full_name
          xml.tag! 'user',          fua.user.user
          xml.tag! 'function',      fua.user.function
          xml.tag! 'process_owner', fua.process_owner
        end
      end
    end
end
