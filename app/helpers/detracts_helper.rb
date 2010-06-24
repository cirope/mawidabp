module DetractsHelper
  def link_to_last_detracts(user)
    link_to_remote t(:'detract.show_last_detracts'),
      :update => 'last_detracts', :method => :get,
      :url => { :action => :show_last_detracts, :id => user.id },
      :loading => 'Helper.showLoading()', :complete => 'Helper.hideLoading()'
  end
end