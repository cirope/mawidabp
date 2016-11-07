module AbilityHelper
  def can? action, subject
    privileges = @auth_privileges[subject]

    privileges && privileges[action]
  end
end
