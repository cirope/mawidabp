require 'test_helper'

# Clase para probar el modelo "ConclusionFinalReview"
class ConclusionFinalReviewTest < ActiveSupport::TestCase
  fixtures :conclusion_reviews

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_current_final_review).id)

    set_organization
  end

  teardown do
    Current.user         = nil
    Current.group        = nil
    Current.organization = nil
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ConclusionFinalReview, @conclusion_review
    fixture_conclusion_review =
      conclusion_reviews(:conclusion_current_final_review)
    assert_equal fixture_conclusion_review.type, @conclusion_review.type
    assert_equal fixture_conclusion_review.review_id,
      @conclusion_review.review_id
    assert_equal fixture_conclusion_review.issue_date,
      @conclusion_review.issue_date
    assert_equal fixture_conclusion_review.applied_procedures,
      @conclusion_review.applied_procedures
    assert_equal fixture_conclusion_review.conclusion,
      @conclusion_review.conclusion
  end

  # Prueba la creación de un informe final
  test 'create' do
    Current.user = users :supervisor
    review = Review.find reviews(:review_approved_with_conclusion).id
    findings_count = (review.weaknesses + review.oportunities).size

    assert findings_count > 0

    if DISABLE_COI_AUDIT_DATE_VALIDATION
      assert review.control_objective_items.all? { |coi| !coi.audit_date.today? }

      coi = review.control_objective_items.take

      coi.update! audit_date: nil
    end

    assert_difference 'ConclusionFinalReview.count' do
      assert_difference 'Finding.count', findings_count do
        @conclusion_review = ConclusionFinalReview.list.new(
          :review => review,
          :issue_date => Date.today,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'New applied procedures',
          :conclusion => CONCLUSION_OPTIONS.first,
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :evolution => EVOLUTION_OPTIONS.second,
          :evolution_justification => 'Ok',
          :main_weaknesses_text => 'Some main weakness X',
          :corrective_actions => 'You should do it this way',
          :objective => 'Some objective',
          :reference => 'Some reference',
          :observations => 'Some observations',
          :scope => 'Some scope',
          :affects_compliance => false
        )

        assert @conclusion_review.save, @conclusion_review.errors.full_messages.join('; ')
        # Asegurarse que le asigna el tipo correcto
        assert_equal 'ConclusionFinalReview', @conclusion_review.type
      end
    end

    final_findings_count = (review.final_weaknesses + review.final_oportunities).size

    assert_equal findings_count, final_findings_count
    assert_not_equal 0, Finding.finals(true).count
    assert Finding.finals(true).all? { |f| f.parent }

    if DISABLE_COI_AUDIT_DATE_VALIDATION
      assert review.control_objective_items.any? { |coi| coi.audit_date.today? }
      assert review.control_objective_items.all? { |coi| coi.audit_date.present? }
    end
  end

  # Prueba la creación de un informe final con observaciones reiteradas
  test 'create with repeated findings' do
    Current.user = users :supervisor
    review = Review.find reviews(:review_approved_with_conclusion).id
    findings = review.weaknesses + review.oportunities
    repeated_id = findings(:being_implemented_weakness).id

    assert findings.size > 0

    assert_difference 'Finding.repeated.count' do
      assert review.update!(
        :finding_review_assignments_attributes => {
          :new_1 => {:finding_id => repeated_id}
        }
      )
      assert findings.detect(&:being_implemented?).update(
        :repeated_of_id => repeated_id
      )
    end

    assert_difference 'ConclusionFinalReview.count' do
      assert_difference 'Finding.count', findings.size do
        @conclusion_review = ConclusionFinalReview.list.new(
          :review => review,
          :issue_date => Date.today,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'New applied procedures',
          :conclusion => CONCLUSION_OPTIONS.first,
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :evolution => EVOLUTION_OPTIONS.second,
          :evolution_justification => 'Ok',
          :main_weaknesses_text => 'Some main weakness X',
          :corrective_actions => 'You should do it this way',
          :objective => 'Some objective',
          :reference => 'Some reference',
          :observations => 'Some observations',
          :scope => 'Some scope',
          :affects_compliance => false
        )

        assert @conclusion_review.save, @conclusion_review.errors.full_messages.join('; ')
        # Asegurarse que le asigna el tipo correcto
        assert_equal 'ConclusionFinalReview', @conclusion_review.type
      end
    end

    final_findings_count = (review.final_weaknesses + review.final_oportunities).size

    assert_equal findings.size, final_findings_count
    assert_not_equal 0, Finding.finals(true).count
    assert Finding.finals(true).all? { |f| f.parent }
  end

  # Prueba de actualización de un informe final
  test 'update' do
    assert @conclusion_review.update(
      :applied_procedures => 'Updated applied procedures'),
      @conclusion_review.errors.full_messages.join('; ')
    @conclusion_review.reload
    # No se puede modificar ningún dato
    assert_not_equal 'Updated applied procedures',
      @conclusion_review.applied_procedures
  end

  # Prueba de eliminación de informes finales
  test 'destroy' do
    skip if ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION

    assert_no_difference 'ConclusionFinalReview.count' do
      @conclusion_review.destroy
    end
  end

  test 'allow destruction' do
    skip unless ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION

    weakness = @conclusion_review.review.weaknesses.first

    weakness.update_column :final, true

    findings_count = @conclusion_review.review.final_weaknesses.count

    assert findings_count > 0

    assert_difference 'ConclusionFinalReview.count', -1 do
      assert_difference 'Finding.finals(true).count', -findings_count do
        @conclusion_review.destroy
      end
    end
  end

  # Prueba la inclusión de observaciones anuladas en ejecución
  test 'revoked weaknesses' do
    review = Review.find reviews(:review_approved_with_conclusion).id
    weakness = Weakness.find findings(:being_implemented_weakness_on_approved_draft).id
    assert weakness.update_attribute :state, 7

    @conclusion_review = ConclusionFinalReview.list.new(
          :review => review,
          :issue_date => Date.today,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'New applied procedures',
          :conclusion => CONCLUSION_OPTIONS.first,
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :evolution => EVOLUTION_OPTIONS.second,
          :evolution_justification => 'Ok',
          :main_weaknesses_text => 'Some main weakness X',
          :corrective_actions => 'You should do it this way',
          :objective => 'Some objective',
          :reference => 'Some reference',
          :observations => 'Some observations',
          :scope => 'Some scope',
          :affects_compliance => false
        )

    assert @conclusion_review.save

    assert weakness.reload.final
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @conclusion_review.issue_date = nil
    @conclusion_review.review_id = nil
    @conclusion_review.applied_procedures = '   '
    @conclusion_review.conclusion = '   '
    @conclusion_review.recipients = '   '
    @conclusion_review.sectors = '   '
    @conclusion_review.evolution = '   '
    @conclusion_review.evolution_justification = '   '

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :issue_date, :blank
    assert_error @conclusion_review, :review_id, :blank
    assert_error @conclusion_review, :conclusion, :blank

    if Current.conclusion_pdf_format == 'gal'
      assert_error @conclusion_review, :recipients, :blank
      assert_error @conclusion_review, :sectors, :blank
      assert_error @conclusion_review, :evolution, :blank
      assert_error @conclusion_review, :evolution_justification, :blank
    else
      assert_error @conclusion_review, :applied_procedures, :blank
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates unique attributes' do
    @conclusion_review.review_id =
      conclusion_reviews(:conclusion_past_final_review).review_id

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :review_id, :taken
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @conclusion_review.issue_date = '13/13/13'

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :issue_date, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates approved review' do
    @conclusion_review.review.conclusion_draft_review.approved = false

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :review_id, :invalid
  end

  test 'validates force approved review' do
    assert @conclusion_review.reload.check_for_approval
    assert @conclusion_review.approved?

    conclusion_draft_review = @conclusion_review.conclusion_draft_review

    assert conclusion_draft_review.approved?

    @conclusion_review.review.update_attribute :survey, nil

    assert conclusion_draft_review.check_for_approval
    assert !conclusion_draft_review.approved?

    # Ahora se elije saltar esta validación
    conclusion_draft_review.force_approval = true

    assert conclusion_draft_review.check_for_approval
    assert conclusion_draft_review.approved?
    assert conclusion_draft_review.save

    assert @conclusion_review.reload.check_for_approval
    assert @conclusion_review.approved?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates invalid draft review' do
    @conclusion_review.review = reviews(:review_without_conclusion)

    assert @conclusion_review.invalid?
    assert_error @conclusion_review, :review_id, :without_draft
  end

  test 'duplicate review findings' do
    Current.user = users :supervisor
    review = Review.find reviews(:review_approved_with_conclusion).id
    review = review.reload
    findings = review.weaknesses + review.oportunities
    final_findings = review.final_weaknesses + review.final_oportunities
    work_papers_count = findings.inject(0) { |acc, f| acc + f.work_papers.size }
    final_work_papers_count = final_findings.inject(0) do |acc, f|
      acc + f.work_papers.size
    end

    assert work_papers_count > 0
    assert_equal 0, final_work_papers_count

    assert_difference 'ConclusionFinalReview.count' do
      @conclusion_review = ConclusionFinalReview.list.new(
        :review => review,
        :issue_date => Date.today,
        :close_date => 2.days.from_now.to_date,
        :applied_procedures => 'New applied procedures',
        :conclusion => CONCLUSION_OPTIONS.first,
        :recipients => 'John Doe',
        :sectors => 'Area 51',
        :evolution => EVOLUTION_OPTIONS.second,
        :evolution_justification => 'Ok',
        :main_weaknesses_text => 'Some main weakness X',
        :corrective_actions => 'You should do it this way',
        :objective => 'Some objective',
        :reference => 'Some reference',
        :observations => 'Some observations',
        :scope => 'Some scope',
        :affects_compliance => false
      )

      assert @conclusion_review.save,
        @conclusion_review.errors.full_messages.join('; ')
    end

    findings = review.weaknesses.reload + review.oportunities.reload
    work_papers_count = findings.inject(0) { |acc, f| acc + f.work_papers.size }
    final_findings = review.reload.final_weaknesses.reload + review.reload.final_oportunities.reload
    final_work_papers_count = final_findings.inject(0) do |acc, f|
      acc + f.work_papers.size
    end

    assert final_work_papers_count > 0
    assert_equal final_work_papers_count, work_papers_count
    assert_not_nil @conclusion_review.issue_date
    assert(findings.all? do |f|
      f.origination_date == @conclusion_review.issue_date
    end)
    assert(final_findings.all? do |f|
      f.origination_date == @conclusion_review.issue_date
    end)
  end

  test 'recode findings on creation' do
    skip unless has_extra_sort_method? Current.organization

    Current.user = users :supervisor
    review       = reviews :review_with_conclusion

    repeated_column = [
      Weakness.quoted_table_name,
      Weakness.qcn('repeated_of_id')
    ].join('.')

    repeated_order = if Review.connection.adapter_name == 'OracleEnhanced'
                        "CASE WHEN #{repeated_column} IS NULL THEN 1 ELSE 0 END"
                      else
                        "#{repeated_column} IS NULL"
                      end

    order = [
      repeated_order,
      "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
      "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
    ].map { |o| Arel.sql o }

    codes = review.weaknesses.not_revoked.reorder(order).pluck 'review_code'

    assert codes.each_with_index.any? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i != i.next
    }

    review.weaknesses.where(:state => Finding::STATUS[:unconfirmed]).each do |w|
      assert w.update_columns :state          => Finding::STATUS[:awaiting],
                              :follow_up_date => 10.days.from_now.to_date
    end

    review.oportunities.where(:state => Finding::STATUS[:unconfirmed]).each do |o|
      assert o.update_columns :state          => Finding::STATUS[:awaiting],
                              :follow_up_date => 10.days.from_now.to_date
    end

    cfr = ConclusionFinalReview.list.create!(
      :review => review,
      :issue_date => Date.today,
      :close_date => 2.days.from_now.to_date,
      :applied_procedures => 'New applied procedures',
      :conclusion => CONCLUSION_OPTIONS.first,
      :recipients => 'John Doe',
      :sectors => 'Area 51',
      :evolution => EVOLUTION_OPTIONS.second,
      :evolution_justification => 'Ok',
      :main_weaknesses_text => 'Some main weakness X',
      :corrective_actions => 'You should do it this way',
      :objective => 'Some objective',
      :reference => 'Some reference',
      :observations => 'Some observations',
      :scope => 'Some scope',
      :affects_compliance => false
    )

    codes = review.weaknesses.reload.not_revoked.reorder(order).pluck 'review_code'

    assert codes.sort.each_with_index.all? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i == i.next
    }
  end

  private

    def has_extra_sort_method? organization
      methods = JSON.parse ENV['AUTOMATICALLY_SORT_FINDINGS_ON_CONCLUSION'] || '{}'

      organization && methods.present? && methods[organization.prefix]
    end
end
