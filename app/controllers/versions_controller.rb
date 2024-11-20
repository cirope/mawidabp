class VersionsController < ApplicationController
  respond_to :html, :pdf

  before_action :auth, :check_privileges
  before_action :set_title

  def index
    @versions = search

    respond_to do |format|
      format.html { @versions = @versions.page(params[:page]) }
      format.pdf  { redirect_to pdf.relative_path }
      format.csv  { render csv: csv, filename: filename }
    end
  end

  # * GET /versions/1
  def show
    @version = PaperTrail::Version.where(
      id: params[:id], organization_id: current_organization.id, important: true
    ).first
  end

  private

    def csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << versions_header_csv

        versions_data_csv.each do |data|
          csv << data
        end
      end

      "\uFEFF#{csv_str}"
    end

    def versions_header_csv
      [
        PaperTrail::Version.human_attribute_name('created_at'),
        PaperTrail::Version.human_attribute_name('whodunnit'),
        PaperTrail::Version.human_attribute_name('item'),
        PaperTrail::Version.human_attribute_name('event'),
        I18n.t('versions.column_attribute'),
        I18n.t('versions.column_old_value'),
        I18n.t('versions.column_new_value')
      ]
    end

   def versions_data_csv
     item = []

     @versions.each do |row|
       row.changeset.map do |attribute, (old_value, new_value)|
         item << [
           row.created_at,
           show_whodunnit(row.whodunnit),
           "#{row.item.class.model_name.human} (#{row.item})",
           I18n.t("versions.events.#{row.event}"),
           attribute,
           old_value,
           new_value
         ]
       end
     end

     item
   end

    def pdf
      VersionPdf.create from: @from_date, to: @to_date, versions: @versions, current_organization: current_organization
    end

    def search
      @from_date, @to_date = *make_date_range(params[:index])

      PaperTrail::Version.where(conditions, parameters).order(created_at: :desc)
    end

    def conditions
      [
        'organization_id = :organization_id',
        'created_at BETWEEN :from_date AND :to_date',
        'item_type IN (:types)', 'important = :boolean_true'
      ].join(' AND ')
    end

    def parameters
      {
        from_date: @from_date.to_time.at_beginning_of_day,
        to_date: @to_date.to_time.at_end_of_day,
        organization_id: current_organization.id,
        types: ['User', 'Parameter', 'Role', 'Privilege', 'OrganizationRole'],
        boolean_true: true
      }
    end

    def filename
      I18n.t 'versions.csv_list_name', from_date: @from_date, to_date: @to_date
    end

    def show_whodunnit whodunnit
      whodunnit ? User.find(whodunnit).full_name_with_user : '-'
    end
end
