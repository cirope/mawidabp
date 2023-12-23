module WelcomeHelper
  def welcome_findings_graph
    content_tag(
      :div, nil, id: 'welcome_findings_graph', class: 'ct-chart',
      data: {
        graph: true,
        findings: Finding.findings_for_graph(@auth_user.findings)
      }
    )
  end
end
