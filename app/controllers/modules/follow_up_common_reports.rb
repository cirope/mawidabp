module FollowUpCommonReports
  def weaknesses_by_state
    @title = t :'follow_up_committee.weaknesses_by_state_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @audit_types = [:internal, :external]
    @weaknesses_counts = {}
    @being_implemented_resumes = {}
    @status = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @audit_types.each do |audit_type|
      @weaknesses_counts["#{audit_type}_weaknesses"] =
        Weakness.list_all_by_date(@from_date, @to_date).send(
          "#{audit_type}_audit").finals(false).count(:group => :state)
      @weaknesses_counts["#{audit_type}_oportunities"] =
        Oportunity.list_all_by_date(@from_date, @to_date).send(
          "#{audit_type}_audit").finals(false).count(:group => :state)
      being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}

      @status.each do |state|
        if state.first == :being_implemented
          being_implemented =
            Weakness.list_all_by_date(@from_date, @to_date).send(
              "#{audit_type}_audit").finals(false).being_implemented

          being_implemented.each do |w|
            unless w.stale?
              unless w.rescheduled?
                being_implemented_counts[:current] += 1
              else
                being_implemented_counts[:current_rescheduled] += 1
              end
            else
              unless w.rescheduled?
                being_implemented_counts[:stale] += 1
              else
                being_implemented_counts[:stale_rescheduled] += 1
              end
            end
          end
        end
      end

      @being_implemented_resumes[audit_type] =
        being_implemented_resume_from_counts(being_implemented_counts)
    end

    unless params[:download].blank?
      pdf = PDF::Writer.create_generic_pdf :landscape

      pdf.add_generic_report_header @auth_organization

      pdf.add_title t(:'follow_up_committee.weaknesses_by_state.title'), 12,
        :center

      pdf.move_pointer 24

      pdf.add_description_item(
        t(:'follow_up_committee.period.title'),
        t(:'follow_up_committee.period.range',
          :from_date => l(@from_date, :format => :long),
          :to_date => l(@to_date, :format => :long)))

      @audit_types.each do |type|
        weaknesses_count = @weaknesses_counts["#{type}_weaknesses"]
        oportunities_count = @weaknesses_counts["#{type}_oportunities"]
        total_weaknesses = weaknesses_count.values.sum
        total_oportunities = oportunities_count.values.sum

        pdf.move_pointer 24

         pdf.add_title t("conclusion_committee_report.findings_type_#{type}"),
          14, :center

        pdf.move_pointer 12

        if (total_weaknesses + total_oportunities) > 0
          columns = {
            'state' => [Finding.human_attribute_name('state'), 30],
            'weaknesses_count' => [
              t(:'conclusion_committee_report.weaknesses_by_state.weaknesses_column'),
              type == :internal ? 35 : 70]
          }
          column_data = []

          if type == :internal
            columns['oportunities_count'] = [
              t(:'conclusion_committee_report.weaknesses_by_state.oportunities_column'), 35]
          end

          columns.each do |col_name, col_data|
            columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
              column.heading = col_data.first
              column.width = pdf.percent_width col_data.last
            end
          end

          @status.each do |state|
            w_count = weaknesses_count[state.last] || 0
            o_count = oportunities_count[state.last] || 0
            weaknesses_percentage = total_weaknesses > 0 ?
              w_count.to_f / total_weaknesses * 100 : 0.0
            oportunities_percentage = total_oportunities > 0 ?
              o_count.to_f / total_oportunities * 100 : 0.0

            column_data << {
              'state' => "<b>#{t("finding.status_#{state.first}")}</b>".to_iso,
              'weaknesses_count' =>
                "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)",
              'oportunities_count' =>
                "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)",
            }

            if state.first == :being_implemented
              if column_data.last['weaknesses_count'] != '0'
                column_data.last['weaknesses_count'] << ' *'
              end
            end
          end

          column_data << {
            'state' =>
              "<b>#{t(:'follow_up_committee.weaknesses_by_state.total')}</b>".to_iso,
            'weaknesses_count' => "<b>#{total_weaknesses}</b>",
            'oportunities_count' => "<b>#{total_oportunities}</b>"
          }

          unless column_data.blank?
            PDF::SimpleTable.new do |table|
              table.width = pdf.page_usable_width
              table.columns = columns
              table.data = column_data
              table.column_order = type == :internal ?
                ['state', 'weaknesses_count', 'oportunities_count'] :
                ['state', 'weaknesses_count']
              table.split_rows = true
              table.font_size = 12
              table.row_gap = 6
              table.shade_rows = :none
              table.shade_heading_color = Color::RGB::Grey50
              table.heading_font_size = 12
              table.shade_headings = true
              table.bold_headings = true
              table.position = :left
              table.orientation = :right
              table.show_lines = :all
              table.render_on pdf
            end
          end

          add_being_implemented_resume(pdf, @being_implemented_resumes[type])
        else
          pdf.text t(:'follow_up_committee.without_weaknesses'),
            :font_size => 12
        end
      end

      pdf.custom_save_as(
        t(:'follow_up_committee.weaknesses_by_state.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_state', 0)

      redirect_to PDF::Writer.relative_path(
        t(:'follow_up_committee.weaknesses_by_state.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_state', 0)
    end
  end

  def weaknesses_by_risk
    @title = t :'follow_up_committee.weaknesses_by_risk_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_risk])
    @audit_types = [:internal, :external]
    @tables_data = {}
    @being_implemented_resumes = {}
    risk_levels = parameter_in(@auth_organization.id,
      :admin_finding_risk_levels, @from_date)
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @audit_types.each do |audit_type|
      weaknesses_count = {}
      weaknesses_count_by_risk = {}
      being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}

      risk_levels.each do |rl|
        weaknesses_count_by_risk[rl[0]] = 0

        statuses.each do |s|
          weaknesses_count[s[1]] ||= {}
            weaknesses_count[s[1]][rl[1]] =
              Weakness.list_all_by_date(@from_date, @to_date).send(
                "#{audit_type}_audit").finals(false).count(
                :conditions => {:state => s[1], :risk => rl[1]})
            weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]

          if s.first == :being_implemented
          being_implemented = Weakness.list_all_by_date(
            @from_date, @to_date).send("#{audit_type}_audit").finals(false).
            being_implemented.find_all_by_risk(rl[1])

            being_implemented.each do |f|
              unless f.stale?
                unless f.respond_to?(:rescheduled?) && f.rescheduled?
                  being_implemented_counts[:current] += 1
                else
                  being_implemented_counts[:current_rescheduled] += 1
                end
              else
                unless f.respond_to?(:rescheduled?) && f.rescheduled?
                  being_implemented_counts[:stale] += 1
                else
                  being_implemented_counts[:stale_rescheduled] += 1
                end
              end
            end
          end
        end
      end

      @being_implemented_resumes[audit_type] =
        being_implemented_resume_from_counts(being_implemented_counts)
      @tables_data[audit_type] = get_weaknesses_synthesis_table_data(
        weaknesses_count, weaknesses_count_by_risk, risk_levels)
    end

    unless params[:download].blank?
      pdf = PDF::Writer.create_generic_pdf :landscape

      pdf.add_generic_report_header @auth_organization

      pdf.add_title t(:'follow_up_committee.weaknesses_by_risk.title'), 12,
        :center

      pdf.move_pointer 24

      pdf.add_description_item(
        t(:'follow_up_committee.period.title'),
        t(:'follow_up_committee.period.range',
          :from_date => l(@from_date, :format => :long),
          :to_date => l(@to_date, :format => :long)))

      @audit_types.each do |type|
        pdf.move_pointer 24

        pdf.add_title t("conclusion_committee_report.weaknesses_type_#{type}"),
          14, :center

        pdf.move_pointer 12

        add_weaknesses_synthesis_table(pdf, @tables_data[type])

        add_being_implemented_resume(pdf, @being_implemented_resumes[type])
      end

      pdf.custom_save_as(
        t(:'follow_up_committee.weaknesses_by_risk.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk', 0)

      redirect_to PDF::Writer.relative_path(
        t(:'follow_up_committee.weaknesses_by_risk.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk', 0)
    end
  end
  
  def weaknesses_by_audit_type
    @title = t :'follow_up_committee.weaknesses_by_audit_type_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_audit_type])
    @audit_types = [:internal, :external]
    @data = {}
    risk_levels = parameter_in(@auth_organization.id,
      :admin_finding_risk_levels, @from_date)
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @audit_types.each do |audit_type|
      @data[audit_type] = []
      conclusion_final_review = ConclusionFinalReview.list_all_by_date(
        @from_date, @to_date).send("#{audit_type}_audit")
      reviews_by_audit_type = {}

      conclusion_final_review.each do |cfr|
        business_unit = cfr.review.plan_item.business_unit
        business_unit_type = business_unit.business_unit_type.name

        reviews_by_audit_type[business_unit_type] ||= {}
        reviews_by_audit_type[business_unit_type][business_unit.name] ||= []
        reviews_by_audit_type[business_unit_type][business_unit.name] << cfr
      end

      reviews_by_audit_type.each do |bu_type, bu_data|
        title = "#{Review.human_attribute_name('audit_type')}: #{bu_type}"
        business_units = {}

        bu_data.values.each do |cfrs|
          unless cfrs.empty?
            business_unit = cfrs.first.plan_item.business_unit
            weaknesses = []
            oportunities = []

            cfrs.sort! do |cfr1, cfr2|
              cfr1.review.effectiveness <=> cfr2.review.effectiveness
            end

            cfrs.each do |cfr|
              review = cfr.review
              weaknesses |= review.weaknesses
              oportunities |= review.oportunities
            end

            grouped_weaknesses = weaknesses.group_by(&:state)
            grouped_oportunities = oportunities.group_by(&:state)
            oportunities_table_data = []
            weaknesses_count = {}
            weaknesses_count_by_risk = {}
            total_oportunities = grouped_oportunities.values.sum(&:size)
            being_implemented_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}

            if total_oportunities > 0
              statuses.each do |s|
                o_count = (grouped_oportunities[s[1]] || []).size
                oportunities_percentage = total_oportunities > 0 ?
                  o_count.to_f / total_oportunities * 100 : 0.0

                oportunities_table_data << {
                  'state' => "<b>#{t("finding.status_#{s[0]}")}</b>".to_iso,
                  'count' =>
                    "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
                }
              end

              oportunities_table_data << {
                'state' =>
                  "<b>#{t(:'conclusion_committee_report.weaknesses_by_audit_type.total')}</b>".to_iso,
                'count' => "<b>#{total_oportunities}</b>"
              }
            end

            risk_levels.each do |rl|
              weaknesses_count_by_risk[rl[0]] = 0

              statuses.each do |s|
                weaknesses_for_status = grouped_weaknesses[s[1]] || {}

                count_for_risk = weaknesses_for_status.inject(0) do |sum, w|
                  sum + (w.risk == rl[1] ? 1 : 0)
                end

                weaknesses_count[s[1]] ||= {}
                weaknesses_count[s[1]][rl[1]] = count_for_risk
                weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]

                if s.first == :being_implemented
                  being_implemented = weaknesses_for_status.select do |w|
                    w.risk == rl[1]
                  end

                  being_implemented.each do |w|
                    unless w.stale?
                      unless w.rescheduled?
                        being_implemented_counts[:current] += 1
                      else
                        being_implemented_counts[:current_rescheduled] += 1
                      end
                    else
                      unless w.rescheduled?
                        being_implemented_counts[:stale] += 1
                      else
                        being_implemented_counts[:stale_rescheduled] += 1
                      end
                    end
                  end
                end
              end
            end

            weaknesses_table_data = get_weaknesses_synthesis_table_data(
              weaknesses_count, weaknesses_count_by_risk, risk_levels)
            being_implemented_resume = being_implemented_resume_from_counts(
              being_implemented_counts)

            business_units[business_unit] = {
              :conclusion_reviews => cfrs,
              :weaknesses_table_data => weaknesses_table_data,
              :oportunities_table_data => oportunities_table_data,
              :being_implemented_resume => being_implemented_resume
            }
          end
        end

        @data[audit_type] << {
          :title => title,
          :business_units => business_units
        }
      end
    end

    unless params[:download].blank?
      pdf = PDF::Writer.create_generic_pdf :landscape

      pdf.add_generic_report_header @auth_organization

      pdf.add_title t(:'follow_up_committee.weaknesses_by_audit_type.title'),
        12, :center

      pdf.move_pointer 24

      pdf.add_description_item(
        t(:'follow_up_committee.period.title'),
        t(:'follow_up_committee.period.range',
          :from_date => l(@from_date, :format => :long),
          :to_date => l(@to_date, :format => :long)))

      @audit_types.each do |type|
        pdf.move_pointer 24

        pdf.add_title t("conclusion_committee_report.findings_type_#{type}"),
          14, :center

        pdf.move_pointer 12

        unless @data[type].blank?
          @data[type].each do |data_item|
            pdf.move_pointer 12
            pdf.add_title data_item[:title], 12, :center

            data_item[:business_units].each do |bu, bu_data|
              pdf.move_pointer 12

              pdf.add_description_item(
                bu.business_unit_type.business_unit_label, bu.name)
              pdf.move_pointer 12

              pdf.text "<b>#{t(:'actioncontroller.reviews')}</b>"
              pdf.move_pointer 12

              bu_data[:conclusion_reviews].each do |cr|
                findings_count = cr.review.weaknesses.size +
                  cr.review.oportunities.size

                text = "<C:bullet /> <b>#{cr.review}</b>: " +
                  cr.review.score_text

                if findings_count == 0
                  text << " (#{t(:'follow_up_committee.weaknesses_by_audit_type.without_weaknesses')})"
                end

                pdf.text text, :left => 24
              end

              pdf.move_pointer 12

              pdf.add_title(
                t(:'follow_up_committee.weaknesses_by_audit_type.weaknesses'), 12)

              pdf.move_pointer 12

              add_weaknesses_synthesis_table(pdf,
                bu_data[:weaknesses_table_data], 10)
              add_being_implemented_resume(pdf,
                bu_data[:being_implemented_resume])

              if type == :internal
                pdf.move_pointer 12

                pdf.add_title(
                  t(:'follow_up_committee.weaknesses_by_audit_type.oportunities'), 12)

                pdf.move_pointer 12

                unless bu_data[:oportunities_table_data].blank?
                  columns = {
                    'state' => [Oportunity.human_attribute_name('state'), 30],
                    'count' => [Oportunity.human_attribute_name('count'), 70]
                  }

                  columns.each do |col_name, col_data|
                    columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
                      column.heading = col_data.first
                      column.width = pdf.percent_width col_data.last
                    end
                  end

                  unless bu_data[:oportunities_table_data].blank?
                    PDF::SimpleTable.new do |table|
                      table.width = pdf.page_usable_width
                      table.columns = columns
                      table.data = bu_data[:oportunities_table_data]
                      table.column_order = ['state', 'count']
                      table.split_rows = true
                      table.font_size = 10
                      table.row_gap = 6
                      table.shade_rows = :none
                      table.shade_heading_color = Color::RGB::Grey50
                      table.heading_font_size = 12
                      table.shade_headings = true
                      table.bold_headings = true
                      table.position = :left
                      table.orientation = :right
                      table.show_lines = :all
                      table.render_on pdf
                    end
                  end
                else
                  pdf.text t(:'follow_up_committee.without_oportunities')
                end
              end
            end
          end
        else
          pdf.text t(:'follow_up_committee.without_weaknesses'),
            :font_size => 12
        end
      end

      pdf.custom_save_as(
        t(:'follow_up_committee.weaknesses_by_audit_type.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_audit_type',
        0)

      redirect_to PDF::Writer.relative_path(
        t(:'follow_up_committee.weaknesses_by_audit_type.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_audit_type',
        0)
    end
  end

  private

  # Devuelve el ID de la organización seleccionada, sólo si el usuario está
  # autorizado para verla. Caso contrario retorna la organización con la que
  # está autenticado el usuario.
  def get_organization #:doc:
    auth_organizations = @auth_user.organizations.map { |o| o.id }
    params[:organization] && auth_organizations.include?(
      params[:organization].to_i) ?
      params[:organization] : @auth_organization.id
  end

  def add_weaknesses_synthesis_table(pdf, data, font_size = 12)
    if data.kind_of?(Hash)
      columns = {}
      column_data = []

      data[:columns].each do |col_name, col_data|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = col_data.first
          c.width = pdf.percent_width col_data.last
        end
      end

      data[:data].each do |row|
        new_row = {}

        row.each {|column, content| new_row[column] = content.to_iso}

        column_data << new_row
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = data[:order]
          table.split_rows = true
          table.font_size = font_size
          table.row_gap = 6
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB::Grey50
          table.heading_font_size = 12
          table.shade_headings = true
          table.bold_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.render_on pdf
        end
      end
    else
      pdf.text "<i>#{data}</i>", :font_size => 12
    end
  end

  def get_weaknesses_synthesis_table_data(weaknesses_count,
      weaknesses_count_by_risk, risk_levels)
    total_count = weaknesses_count_by_risk.sum(&:second)

    unless total_count == 0
      risk_level_values = risk_levels.map { |rl| rl[0] }.reverse
      statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
        sort { |s1, s2| s1.last <=> s2.last }
      column_order = ['state', risk_level_values, 'count'].flatten
      column_data = []
      columns = {
        'state' => [Weakness.human_attribute_name('state'), 30],
        'count' => [Weakness.human_attribute_name('count'), 15]
      }

      risk_levels.each {|rl| columns[rl[0]] = [rl[0], (55 / risk_levels.size)]}

      statuses.each do |state|
        sub_total_count = weaknesses_count[state.last].sum(&:second)
        percentage_total = 0
        column_row = {'state' => "<b>#{t("finding.status_#{state.first}")}</b>"}

        risk_levels.each do |rl|
          count = weaknesses_count[state.last][rl.last]
          percentage = sub_total_count > 0 ?
            (count * 100.0 / sub_total_count).round(2) : 0.0

          column_row[rl.first] = count > 0 ?
            "#{count} (#{'%.2f' % percentage}%)" : '-'
          percentage_total += percentage
        end

        column_row['count'] = sub_total_count > 0 ?
          "<b>#{sub_total_count} (#{'%.1f' % percentage_total}%)</b>" : '-'

        if state.first == :being_implemented && sub_total_count != 0
          column_row['count'] << '*'
        end

        column_data << column_row
      end

      column_row = {
        'state' => "<b>#{t(:'follow_up_committee.weaknesses_by_risk.total')}</b>",
        'count' => "<b>#{total_count}</b>"
      }

      weaknesses_count_by_risk.each do |risk, count|
        column_row[risk] = "<b>#{count}</b>"
      end

      column_data << column_row

      {:order => column_order, :data => column_data, :columns => columns}
    else
      t(:'follow_up_committee.without_weaknesses')
    end
  end

  def add_being_implemented_resume(pdf, being_implemented_resume = nil)
    unless being_implemented_resume.blank?
      pdf.move_pointer 12

      pdf.text "* #{being_implemented_resume}", :font_size => 10
    end
  end

  def being_implemented_resume_from_counts(being_implemented_counts = {})
    being_implemented_resume = []
    total_of_being_implemented = being_implemented_counts.values.sum
    sub_statuses = [:current, :current_rescheduled, :stale, :stale_rescheduled]

    sub_statuses.each do |sub_status|
      count = being_implemented_counts[sub_status]
      sub_status_percentage = count == 0 ?
        0.00 : (count.to_f / total_of_being_implemented) * 100
      sub_status_resume = "<b>#{count}</b> "
      sub_status_resume << t(
        "follow_up_committee.weaknesses_being_implemented_#{sub_status}")
      sub_status_resume << " (#{'%.2f' % sub_status_percentage}%)"

      being_implemented_resume << sub_status_resume
    end

    unless being_implemented_resume.blank? || total_of_being_implemented == 0
      being_implemented_resume.to_sentence
    end
  end
end