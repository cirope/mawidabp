module UsersHelper
  def show_user_with_email_as_abbr(user)
    content_tag(:abbr, h(user.user), :title => user.email)
  end

  def user_resource_field(form, inline = true)
    resource_classes = ResourceClass.human_resources
    
    form.grouped_collection_select(:resource_id, resource_classes, :resources,
      :to_s, :id, :to_s,
      {:prompt => true},
      {:class => (:inline_item if inline)})
  end

  def user_language_field(form, inline = true)
    options = AVAILABLE_LOCALES.map { |lang| [t("lang.#{lang}"), lang.to_s] }

    form.select :language, options.sort{ |a, b| a[0] <=> b[0] }, {},
      {:class => (:inline_item if inline)}
  end

  def user_organizations_field(form, id = nil )
    group = @auth_organization ? @auth_organization.group :
      Group.find_by_admin_hash(params[:hash])
    
    form.select :organization_id, sorted_options_array_for(
      Organization.list_for_group(group), :name, :id), {:prompt => true},
      {:id => "#{id}_organization_id"}
  end

  def draw_user_weaknesses_graph(user, findings, image_label = nil)
    @seq ||= 0
    g = Gruff::Pie.new
    gruped_findings = findings.group_by(&:state)
    g.theme_pastel
    g.no_data_message = t(:'label.without_data')

    gruped_findings.each do |status, weaknesses|
      g.data "#{weaknesses.first.state_text} (#{weaknesses.size})",
        weaknesses.size
    end

    path_without_root = ('%08d' % @auth_organization.id).scan(/\d{4}/) +
      ('%08d' % @auth_user.id).scan(/\d{4}/) + ['graph', user.user]
    fs_path = "#{PRIVATE_PATH}#{path_without_root.join(File::SEPARATOR)}"

    FileUtils.mkdir_p fs_path

    image_name = "findings_#{@seq += 1}.gif"
    image_path = "#{fs_path}#{File::SEPARATOR}#{image_name}"

    g.write image_path

    img = Magick::ImageList.new image_path
    img.resize! 0.5
    img.write image_path

    size = Paperclip::Geometry.from_file(File.new(image_path, 'r'))

    image_tag("/private/#{path_without_root.join('/')}/#{image_name}",
      :size => size.to_s, :alt => image_label)
  end
  
  def user_weaknesses_links(user)
    filtered_weaknesses = user.weaknesses.for_current_organization.finals(
      false).not_incomplete
    pending_count = filtered_weaknesses.with_pending_status.count
    complete_count = filtered_weaknesses.count - pending_count
    
    pending_link = link_to_unless(pending_count == 0,
      textilize_without_paragraph(
        t(:'user.weaknesses.pending', :count => pending_count)
      ), findings_path(:completed => 'incomplete', :user_id => user.id)
    )
    complete_link = link_to_unless(complete_count == 0,
      textilize_without_paragraph(
        t(:'user.weaknesses.complete', :count => complete_count)
      ), findings_path(:completed => 'complete', :user_id => user.id)
    )
    
    raw("#{pending_link} | #{complete_link}")
  end
end