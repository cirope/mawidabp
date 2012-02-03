class MailObserver
  def self.delivered_email(message)
    organization = Organization.find_by_prefix(
      message.subject.match(/\[(\w+)\]/)[1].downcase
    ) rescue nil
    
    body = message.body.decoded.present? ? message.body.decoded :
      message.parts.detect { |p| p.content_type.match(/text/) }.try(:body).try(:decoded)
    
    EMail.create!(
      :to => message.to.join(', '),
      :subject => message.subject,
      :body => body,
      :attachments => message.attachments.map(&:filename).join('; '),
      :organization_id => organization.try(:id)
    )
  end
end