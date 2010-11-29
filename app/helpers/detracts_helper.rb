module DetractsHelper
  def link_to_last_detracts(user)
    link_to t(:'detract.show_last_detracts'),  :remote => true,
      :update => 'last_detracts', :method => :get,
      :url => { :action => :show_last_detracts, :id => user.id },
      :loading => 'Helper.showLoading()', :complete => 'Helper.hideLoading()'
  end
end