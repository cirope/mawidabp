module DetractsHelper
  def link_to_last_detracts(user)
    link_to t(:'detract.show_last_detracts'),
      { :action => :show_last_detracts, :id => user.id }, :remote => true,
      :'data-update' => :last_detracts, :'data-remote-method' => :get
  end
end