class VersionsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges
  hide_action :download_security_changes_report, :load_privileges

  # Muestra el detalle de un cambio en un modelo
  #
  # * GET /versions/1
  # * GET /versions/1.xml
  def show
    @title = t 'version.show_title'
    @version = PaperTrail::Version.where(
      id: params[:id],
      organization_id: @auth_organization.id,
      important: true
    ).first

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @version }
    end
  end

  # Listado de los cambios en los modelos de seguridad
  #
  # * GET /versions/security_changes_report
  def security_changes_report
    @title = t 'version.security_changes_report_title'
    @from_date, @to_date = *make_date_range(params[:security_changes_report])

    unless params[:download]
      @versions = PaperTrail::Version.where(
        [
          'organization_id = :organization_id',
          'created_at BETWEEN :from_date AND :to_date',
          'item_type IN (:types)',
          'important = :boolean_true'
        ].join(' AND '),
        {
          from_date: @from_date,
          to_date: @to_date.to_time.end_of_day,
          organization_id: @auth_organization.id,
          types: ['User', 'Parameter'],
          boolean_true: true
        }
      ).order('created_at DESC').paginate(
        page: params[:page], per_page: APP_LINES_PER_PAGE
      )

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render xml: @versions }
      end
    else
      download_security_changes_report
    end
  end

  private

  def download_security_changes_report
    versions = PaperTrail::Version.where(
      [
        'organization_id = :organization_id',
        'created_at BETWEEN :from_date AND :to_date',
        'item_type IN (:types)',
        'important = :boolean_true'
      ].join(' AND '),
      {
        from_date: @from_date,
        to_date: @to_date.to_time.end_of_day,
        organization_id: @auth_organization.id,
        types: ['User', 'Parameter'],
        boolean_true: true
      }
    ).order('created_at DESC')

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
    pdf.add_title @title

    column_order = [['created_at', 12], ['whodunnit', 28], ['item', 50],
      ['event', 10]]
    column_data, column_headers, column_widths = [], [], []

    column_order.each do |col_name, col_width|
      column_headers << PaperTrail::Version.human_attribute_name(col_name)
      column_widths << pdf.percent_width(col_width)
    end

    versions.each do |version|
      column_data << [
        l(version.created_at, format: :minimal),
        version.whodunnit ?
          User.find(version.whodunnit).full_name_with_user : '-',
        version.item ?
          "#{version.item.class.model_name.human} (#{version.item})" :
          '-',
        t("version.event_#{version.event}")
      ]
    end

    pdf.move_down PDF_FONT_SIZE

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    pdf_name = t('version.pdf_list_name',
      from_date: @from_date.to_formatted_s(:db),
      to_date: @to_date.to_formatted_s(:db))

    pdf.custom_save_as(pdf_name, PaperTrail::Version.table_name)

    redirect_to Prawn::Document.relative_path(pdf_name, PaperTrail::Version.table_name)
  end

  def load_privileges #:nodoc:
    @action_privileges.update(security_changes_report: :read)
  end
end
