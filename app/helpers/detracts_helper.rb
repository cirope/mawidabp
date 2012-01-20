module DetractsHelper
  def link_to_last_detracts(user)
    link_to t('detract.show_last_detracts'),
      { :action => :show_last_detracts, :id => user.id },
      :class => :show_last_detracts, :remote => true, :method => :get
  end
end