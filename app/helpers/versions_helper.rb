module VersionsHelper
  def show_whodunnit(whodunnit)
    whodunnit ? User.find(whodunnit).full_name_with_user : '-'
  end
end