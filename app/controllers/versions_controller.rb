class VersionsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :download_security_changes_report, :load_privileges

  # Muestra el detalle de un cambio en un modelo
  #
  # * GET /versions/1
  # * GET /versions/1.xml
  def show
    @title = t :'version.show_title'
    @version = Version.first(
      :conditions => {
        :id => params[:id],
        :organization_id => @auth_organization.id,
        :important => true
      }
    )

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @version }
    end
  end

  # Listado de los cambios en los modelos de seguridad
  #
  # * GET /versions/security_changes_report
  def security_changes_report
    @title = t :'version.security_changes_report_title'
    @from_date, @to_date = *make_date_range(params[:security_changes_report])

    unless params[:download]
      @versions = Version.paginate(
        :page => params[:page],
        :per_page => APP_LINES_PER_PAGE,
        :conditions => [
          [
            'organization_id = :organization_id',
            'created_at BETWEEN :from_date AND :to_date',
            'item_type IN (:types)',
            'important = :boolean_true'
          ].join(' AND '),
          {
            :from_date => @from_date,
            :to_date => @to_date.to_time.end_of_day,
            :organization_id => @auth_organization.id,
            :types => ['User', 'Parameter'],
            :boolean_true => true
          }
        ],
        :order => 'created_at DESC')

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @versions }
      end
    else
      download_security_changes_report
    end
  end

  private

  def download_security_changes_report
    versions = Version.all(
      :conditions => [
        [
          'organization_id = :organization_id',
          'created_at BETWEEN :from_date AND :to_date',
          'item_type IN (:types)',
          'important = :boolean_true'
        ].join(' AND '),
        {
          :from_date => @from_date,
          :to_date => @to_date.to_time.end_of_day,
          :organization_id => @auth_organization.id,
          :types => ['User', 'Parameter'],
          :boolean_true => true
        }
      ],
      :order => 'created_at DESC')

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
    pdf.add_title @title

    column_order = [['created_at', 12], ['whodunnit', 28], ['item', 50],
      ['event', 10]]
    columns = {}
    column_data = []

    column_order.each do |col_name, col_with|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
        c.heading = Version.human_attribute_name col_name
        c.width = pdf.percent_width col_with
      end
    end

    versions.each do |version|
      column_data << {
        'created_at' => l(version.created_at, :format => :minimal).to_iso,
        'whodunnit' => version.whodunnit ?
          User.find(version.whodunnit).full_name_with_user.to_iso : '-',
        'item' => version.item ?
          "#{version.item.class.model_name.human} (#{version.item})".to_iso :
          '-',
        'event' => t("version.event_#{version.event}").to_iso
      }
    end

    pdf.move_pointer PDF_FONT_SIZE

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = column_order.map(&:first)
        table.split_rows = true
        table.font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_color = Color::RGB.from_percentage(95, 95, 95)
        table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
        table.heading_font_size = PDF_FONT_SIZE
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end

    pdf_name = t(:'version.pdf_list_name',
      :from_date => @from_date.to_formatted_s(:db),
      :to_date => @to_date.to_formatted_s(:db))

    pdf.custom_save_as(pdf_name, Version.table_name)

    redirect_to PDF::Writer.relative_path(pdf_name, Version.table_name)
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :security_changes_report => :read
      })
  end
end