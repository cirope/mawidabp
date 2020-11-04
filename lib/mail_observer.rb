class ::MailObserver
  def self.delivered_email(message)
    match        = message.subject.match(/\A\[(\w+\W*\w*)\]/)
    organization = if match && match[1]
                     Organization.where(
                       "LOWER(#{Organization.qcn 'prefix'}) = ?",
                       match[1].downcase
                     ).take
                   end

    body = if message.body.decoded.present?
             message.body.decoded
           else
             message.parts.detect do |p|
               p.content_type.match(/text/)
             end.try(:body).try(:decoded)
           end

    EMail.create!(
      :to => message.to.join(', '),
      :subject => message.subject,
      :body => body,
      :attachments => message.attachments.map(&:filename).join('; '),
      :organization_id => organization.try(:id)
    )
  end
end
