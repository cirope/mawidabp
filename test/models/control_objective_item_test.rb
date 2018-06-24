require 'test_helper'

# Clase para probar el modelo "ControlObjectiveItem"
class ControlObjectiveItemTest < ActiveSupport::TestCase
  fixtures :control_objective_items, :control_objectives, :reviews, :controls
  include ActionDispatch::TestProcess

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    set_organization

    @control_objective_item = ControlObjectiveItem.find control_objective_items(
      :management_dependency_item_editable).id
  end

  teardown do
    Current.organization_id = nil
    Current.group_id = nil
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    retrived_coi = control_objective_items(:management_dependency_item_editable)
    assert_kind_of ControlObjectiveItem, @control_objective_item
    assert_equal retrived_coi.control_objective_text,
      @control_objective_item.control_objective_text
    assert_equal retrived_coi.relevance, @control_objective_item.relevance
    assert_equal retrived_coi.design_score,
      @control_objective_item.design_score
    assert_equal retrived_coi.compliance_score,
      @control_objective_item.compliance_score
    assert_equal retrived_coi.audit_date, @control_objective_item.audit_date
    assert_equal retrived_coi.auditor_comment,
      @control_objective_item.auditor_comment
    assert_equal retrived_coi.finished, @control_objective_item.finished
  end

  # Prueba la creación de un item de objetivo de control
  test 'create' do
    assert_difference ['ControlObjectiveItem.count', 'Control.count'] do
      @control_objective_item = ControlObjectiveItem.list.create(
        :control_objective_text => 'New text',
        :relevance => ControlObjectiveItem.relevances_values.last,
        :design_score => ControlObjectiveItem.qualifications_values.last,
        :compliance_score => ControlObjectiveItem.qualifications_values.last,
        :sustantive_score => ControlObjectiveItem.qualifications_values.last,
        :audit_date => 10.days.from_now.to_date,
        :auditor_comment => 'New comment',
        :control_objective_id =>
          control_objectives(:organization_security_4_1).id,
        :review_id => reviews(:review_with_conclusion).id,
        :control_attributes => {
          :control => 'New control',
          :effects => 'New effects',
          :design_tests => 'New design tests',
          :compliance_tests => 'New compliance tests',
          :sustantive_tests => 'New compliance tests'
        }
      )
    end
  end

  # Prueba de actualización de un item de objetivo de control
  test 'update' do
    assert @control_objective_item.update(
      :control_objective_text => 'Updated text'),
      @control_objective_item.errors.full_messages.join('; ')

    @control_objective_item.reload
    assert_equal 'Updated text', @control_objective_item.control_objective_text
  end

  # Prueba de eliminación de items de objetivos de control
  test 'destroy' do
    assert_no_difference 'ControlObjectiveItem.count' do
      @control_objective_item.destroy
    end

    control_objective_item = control_objective_items(
      :organization_security_4_3_item_editable_without_findings
    )

    # Sin observaciones es posible eliminar
    assert_difference 'ControlObjectiveItem.count', -1 do
      control_objective_item.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @control_objective_item.control_objective_text = '  '
    @control_objective_item.control_objective_id = nil
    @control_objective_item.issues_count = nil
    @control_objective_item.alerts_count = nil

    assert @control_objective_item.invalid?
    assert_error @control_objective_item, :control_objective_text, :blank
    assert_error @control_objective_item, :control_objective_id, :blank

    if validate_counts?
      assert_error @control_objective_item, :issues_count, :blank
      assert_error @control_objective_item, :alerts_count, :blank
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @control_objective_item.control_objective_id = control_objective_items(
      :impact_analysis_item_editable).control_objective_id

    if ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION
      assert @control_objective_item.valid?
    else
      assert @control_objective_item.invalid?
      assert_error @control_objective_item, :control_objective_id, :taken
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @control_objective_item.relevance = '?123'
    @control_objective_item.audit_date = '?123'
    @control_objective_item.finished = false

    assert @control_objective_item.invalid?
    assert_error @control_objective_item, :relevance, :not_a_number
    assert_error @control_objective_item, :audit_date, :invalid_date
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates date between a period' do
    period_end = @control_objective_item.review.period.end
    @control_objective_item.audit_date = period_end.tomorrow

    assert @control_objective_item.invalid?
    assert_error @control_objective_item, :audit_date, :out_of_period
  end

  test 'effectiveness with only compliance score' do
    high_qualification_value = ControlObjectiveItem.qualifications_values.max

    @control_objective_item.design_score = nil
    @control_objective_item.compliance_score = high_qualification_value - 1
    @control_objective_item.sustantive_score = nil

    assert_equal (high_qualification_value - 1) * 100 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'business unit type ids' do
    assert @control_objective_item.business_unit_scores.blank?
    assert_difference '@control_objective_item.business_unit_scores.size', 2 do
      @control_objective_item.business_unit_type_ids = [business_unit_types(:cycle).id]
    end

    assert_no_difference '@control_objective_item.business_unit_scores.size' do
      @control_objective_item.business_unit_type_ids = [business_unit_types(:cycle).id]
    end
  end

  test 'review effectiveness modification' do
    if HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS || use_review_weaknesses_score?
      skip
    end

    min_qualification_value = ControlObjectiveItem.qualifications_values.min
    review = @control_objective_item.review

    review.save!

    old_score = review.score

    assert_not_equal min_qualification_value,
      @control_objective_item.compliance_score
    assert review.update(
      :control_objective_items_attributes => {
        @control_objective_item.id => {
          :id => @control_objective_item.id,
          :compliance_score => min_qualification_value
        }
      }
    )

    assert_not_equal old_score, review.score
  end

  test 'effectiveness with only design score' do
    high_qualification_value = ControlObjectiveItem.qualifications_values.max

    @control_objective_item.design_score = high_qualification_value - 1
    @control_objective_item.compliance_score = nil
    @control_objective_item.sustantive_score = nil

    assert_equal (high_qualification_value - 1) * 100 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'effectiveness with only sustantive score' do
    high_qualification_value = ControlObjectiveItem.qualifications_values.max

    @control_objective_item.design_score = nil
    @control_objective_item.compliance_score = nil
    @control_objective_item.sustantive_score = high_qualification_value - 1

    assert_equal (high_qualification_value - 1) * 100 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'effectiveness with all scores' do
    high_qualification_value = ControlObjectiveItem.qualifications_values.max

    @control_objective_item.design_score = high_qualification_value
    @control_objective_item.compliance_score = high_qualification_value - 1
    @control_objective_item.sustantive_score = high_qualification_value - 2

    assert_equal (high_qualification_value - 1) * 100 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'validations when is finished' do
    @control_objective_item.design_score = nil
    @control_objective_item.compliance_score = nil
    @control_objective_item.sustantive_score = nil
    @control_objective_item.audit_date = nil
    @control_objective_item.relevance = nil
    @control_objective_item.finished = false
    @control_objective_item.control.effects = '   '
    @control_objective_item.control.control = '   '
    @control_objective_item.auditor_comment = '   '
    @control_objective_item.control.design_tests = '   '
    @control_objective_item.control.compliance_tests = '   '
    @control_objective_item.control.sustantive_tests = '   '

    assert @control_objective_item.valid?

    @control_objective_item.finished = true

    assert @control_objective_item.invalid?
    assert_error @control_objective_item, :audit_date, :blank
    assert_error @control_objective_item, :relevance, :blank
    assert_error @control_objective_item.control, :control, :blank
    assert_error @control_objective_item, :auditor_comment, :blank

    unless HIDE_CONTROL_EFFECTS
      assert_error @control_objective_item.control, :effects, :blank
    end

    assert_error @control_objective_item.control, :design_tests, :blank
    assert_error @control_objective_item.control, :compliance_tests, :blank
    assert_error @control_objective_item.control, :sustantive_tests, :blank

    @control_objective_item.design_score = 0

    expected_error_count = HIDE_CONTROL_EFFECTS ? 5 : 6

    assert !@control_objective_item.valid?
    assert_equal expected_error_count, @control_objective_item.errors.count
    assert @control_objective_item.errors[:compliance_score].blank?
    assert @control_objective_item.errors[:sustantive_score].blank?
    assert_error @control_objective_item.control, :design_tests, :blank
  end

  test 'validations when is excluded from score' do
    @control_objective_item.finished = false
    @control_objective_item.auditor_comment = '   '

    assert @control_objective_item.valid?

    @control_objective_item.exclude_from_score = true

    assert @control_objective_item.invalid?
    assert_error @control_objective_item, :auditor_comment, :blank
  end

  test 'effectiveness with design and compliance scores' do
    high_qualification_value = ControlObjectiveItem.qualifications_values.max

    @control_objective_item.design_score = 0
    @control_objective_item.compliance_score = high_qualification_value - 1
    @control_objective_item.sustantive_score = nil

    # La calificación de post sólo participa en el 50% del cálculo de
    # efectividad
    assert_equal (high_qualification_value - 1) * 50 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'must be approved' do
    assert @control_objective_item.finished?
    assert_not_nil @control_objective_item.compliance_score
    assert @control_objective_item.relevance > 0

    assert @control_objective_item.must_be_approved?
    assert @control_objective_item.approval_errors.blank?

    @control_objective_item.relevance = nil
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.design_score = nil
    @control_objective_item.compliance_score = nil
    @control_objective_item.sustantive_score = nil
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.exclude_from_score = true
    assert @control_objective_item.must_be_approved?

    @control_objective_item.reload
    @control_objective_item.finished = false
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.control.effects = '  '

    if HIDE_CONTROL_EFFECTS
      assert @control_objective_item.must_be_approved?
    else
      assert !@control_objective_item.must_be_approved?
      assert_equal 1, @control_objective_item.approval_errors.size
    end

    @control_objective_item.reload
    @control_objective_item.control.control = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.control.compliance_tests = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.auditor_comment = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    assert @control_objective_item.design_score
    @control_objective_item.control.design_tests = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.design_score = nil
    @control_objective_item.control.design_tests = '  '
    assert @control_objective_item.must_be_approved?
    assert @control_objective_item.approval_errors.blank?

    @control_objective_item.reload
    @control_objective_item.audit_date =
      @control_objective_item.review.conclusion_draft_review.issue_date + 1.day
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    assert @control_objective_item.reload.must_be_approved?
    assert @control_objective_item.approval_errors.blank?
  end

  test 'can be modified' do
    uneditable_control_objective_item = ControlObjectiveItem.find(
      control_objective_items(:management_dependency_item).id)

    @control_objective_item.control_objective_text = 'Updated text'

    assert !@control_objective_item.is_in_a_final_review?
    assert @control_objective_item.can_be_modified?

    assert uneditable_control_objective_item.is_in_a_final_review?

    # Puede ser "modificado" porque no se ha actualizado ninguno de sus
    # atributos
    assert uneditable_control_objective_item.can_be_modified?

    uneditable_control_objective_item.control_objective_text = 'Updated text'

    # No puede ser actualizado porque se ha modificado un atributo
    assert !uneditable_control_objective_item.can_be_modified?
    assert !uneditable_control_objective_item.save

    assert_no_difference 'ControlObjectiveItem.count' do
      uneditable_control_objective_item.destroy
    end
  end

  test 'work papers can be added to uneditable control objectives' do
    uneditable_control_objective_item = ControlObjectiveItem.find(
      control_objective_items(:management_dependency_item).id)

    assert_no_difference 'ControlObjectiveItem.count' do
      assert_difference 'WorkPaper.count' do
        uneditable_control_objective_item.update({
        :work_papers_attributes => {
            '1_new' => {
              :name => 'New workpaper name',
              :code => 'PTOC 20',
              :number_of_pages => '10',
              :description => 'New workpaper description',
              :organization_id => organizations(:cirope).id,
              :file_model_attributes => {
                :file => fixture_file_upload(TEST_FILE, 'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'work papers can not be added to uneditable and closed control objectives' do
    uneditable_control_objective_item = ControlObjectiveItem.find(
      control_objective_items(:security_policy_3_1_item).id)

    assert_no_difference ['ControlObjectiveItem.count', 'WorkPaper.count'] do
      assert_raise(RuntimeError) do
        uneditable_control_objective_item.update({
        :work_papers_attributes => {
            '1_new' => {
              :name => 'New workpaper name',
              :code => 'New workpaper code',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:cirope).id,
              :file_model_attributes => {
                :file => fixture_file_upload(TEST_FILE, 'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'to pdf' do
    FileUtils.rm_f @control_objective_item.absolute_pdf_path

    assert_nothing_raised do
      @control_objective_item.to_pdf(organizations(:cirope))
    end

    assert File.exist?(@control_objective_item.absolute_pdf_path)
    assert File.size(@control_objective_item.absolute_pdf_path) > 0

    FileUtils.rm @control_objective_item.absolute_pdf_path
  end

  private

    def use_review_weaknesses_score?
      organization = Organization.find Current.organization_id

      ORGANIZATIONS_WITH_REVIEW_SCORE_BY_WEAKNESS.include? organization.prefix
    end

    def validate_counts?
      organization = Organization.find Current.organization_id

      ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include? organization.prefix
    end
end
