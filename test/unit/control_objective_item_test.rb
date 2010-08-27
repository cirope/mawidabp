require 'test_helper'

# Clase para probar el modelo "ControlObjectiveItem"
class ControlObjectiveItemTest < ActiveSupport::TestCase
  fixtures :control_objective_items, :control_objectives, :reviews, :controls

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @control_objective_item = ControlObjectiveItem.find control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    retrived_coi = control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable)
    assert_kind_of ControlObjectiveItem, @control_objective_item
    assert_equal retrived_coi.control_objective_text,
      @control_objective_item.control_objective_text
    assert_equal retrived_coi.relevance, @control_objective_item.relevance
    assert_equal retrived_coi.pre_audit_qualification,
      @control_objective_item.pre_audit_qualification
    assert_equal retrived_coi.post_audit_qualification,
      @control_objective_item.post_audit_qualification
    assert_equal retrived_coi.audit_date, @control_objective_item.audit_date
    assert_equal retrived_coi.auditor_comment,
      @control_objective_item.auditor_comment
    assert_equal retrived_coi.finished, @control_objective_item.finished
  end

  # Prueba la creación de un item de objetivo de control
  test 'create' do
    assert_difference ['ControlObjectiveItem.count', 'Control.count'] do
      @control_objective_item = ControlObjectiveItem.create(
        :control_objective_text => 'New text',
        :relevance =>
          get_test_parameter(:admin_control_objective_importances).last[1],
        :pre_audit_qualification =>
          get_test_parameter(:admin_control_objective_qualifications).last[1],
        :post_audit_qualification =>
          get_test_parameter(:admin_control_objective_qualifications).last[1],
        :audit_date => 10.days.from_now.to_date,
        :auditor_comment => 'New comment',
        :control_objective_id =>
          control_objectives(:iso_27000_security_organization_4_1).id,
        :review_id => reviews(:review_with_conclusion).id,
        :controls_attributes => {
          :new_1 => {
            :control => 'New control',
            :effects => 'New effects',
            :design_tests => 'New design tests',
            :compliance_tests => 'New compliance tests'
          }
        }
      )
    end
  end

  # Prueba de actualización de un item de objetivo de control
  test 'update' do
    assert @control_objective_item.update_attributes(
      :control_objective_text => 'Updated text'),
      @control_objective_item.errors.full_messages.join('; ')
    
    @control_objective_item.reload
    assert_equal 'Updated text', @control_objective_item.control_objective_text
  end

  # Prueba de eliminación de items de objetivos de control
  test 'delete' do
    assert_difference 'ControlObjectiveItem.count', -1 do
      @control_objective_item.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @control_objective_item.control_objective_text = '  '
    @control_objective_item.control_objective_id = nil
    assert @control_objective_item.invalid?
    assert_equal 2, @control_objective_item.errors.count
    assert_equal error_message_from_model(@control_objective_item, 
      :control_objective_text, :blank),
      @control_objective_item.errors.on(:control_objective_text)
    assert_equal error_message_from_model(@control_objective_item,
      :control_objective_id, :blank),
      @control_objective_item.errors.on(:control_objective_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @control_objective_item.control_objective_id = control_objective_items(
      :bcra_A4609_data_proccessing_impact_analisys_item_editable).control_objective_id
    assert @control_objective_item.invalid?
    assert_equal 1, @control_objective_item.errors.count
    assert_equal error_message_from_model(@control_objective_item,
      :control_objective_id, :taken), @control_objective_item.errors.on(
      :control_objective_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @control_objective_item.control_objective_id = '?nil'
    @control_objective_item.review_id = '?123'
    @control_objective_item.relevance = '?123'
    @control_objective_item.audit_date = '?123'
    @control_objective_item.finished = false
    assert @control_objective_item.invalid?
    assert_equal 4, @control_objective_item.errors.count
    assert_equal error_message_from_model(@control_objective_item,
      :control_objective_id, :not_a_number),
      @control_objective_item.errors.on(:control_objective_id)
    assert_equal error_message_from_model(@control_objective_item,
      :relevance, :not_a_number), @control_objective_item.errors.on(:relevance)
    assert_equal error_message_from_model(@control_objective_item,
      :review_id, :not_a_number),
      @control_objective_item.errors.on(:review_id)
    assert_equal error_message_from_model(@control_objective_item, :audit_date,
      :invalid_date), @control_objective_item.errors.on(:audit_date)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates date between a period' do
    period_end = @control_objective_item.review.period.end
    @control_objective_item.audit_date = period_end.tomorrow
    assert @control_objective_item.invalid?
    assert_equal 1, @control_objective_item.errors.count
    assert_equal error_message_from_model(@control_objective_item,
      :audit_date, :out_of_period),
      @control_objective_item.errors.on(:audit_date)
  end

  test 'effectiveness without pre audit qualification' do
    qualifications = @control_objective_item.get_parameter(
      :admin_control_objective_qualifications)
    high_qualification_value = qualifications.map { |item| item[1].to_i }.max

    @control_objective_item.post_audit_qualification =
      high_qualification_value - 1
    @control_objective_item.pre_audit_qualification = nil

    assert_equal (high_qualification_value - 1) * 100 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'effectiveness without post audit qualification' do
    qualifications = @control_objective_item.get_parameter(
      :admin_control_objective_qualifications)
    high_qualification_value = qualifications.map { |item| item[1].to_i }.max

    @control_objective_item.post_audit_qualification = nil
    @control_objective_item.pre_audit_qualification =
      high_qualification_value - 1

    assert_equal (high_qualification_value - 1) * 100 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'validations when is finished' do
    @control_objective_item.post_audit_qualification = nil
    @control_objective_item.pre_audit_qualification = nil
    @control_objective_item.audit_date = nil
    @control_objective_item.relevance = nil
    @control_objective_item.finished = false
    @control_objective_item.controls[0].effects = '   '
    @control_objective_item.controls[0].control = '   '
    @control_objective_item.controls[0].compliance_tests = '   '
    @control_objective_item.auditor_comment = '   '
    @control_objective_item.controls[0].design_tests = '   '

    assert @control_objective_item.valid?

    @control_objective_item.finished = true

    assert @control_objective_item.invalid?
    assert_equal 6, @control_objective_item.errors.count
    assert_equal error_message_from_model(@control_objective_item,
      :post_audit_qualification, :blank),
      @control_objective_item.errors.on(:post_audit_qualification)
    assert_equal error_message_from_model(@control_objective_item,
      :audit_date, :blank), @control_objective_item.errors.on(:audit_date)
    assert_equal error_message_from_model(@control_objective_item,
      :relevance, :blank), @control_objective_item.errors.on(:relevance)
    assert_equal error_message_from_model(@control_objective_item.controls[0],
      :effects, :blank), @control_objective_item.controls[0].errors.on(:effects)
    assert_equal error_message_from_model(@control_objective_item.controls[0],
      :control, :blank), @control_objective_item.controls[0].errors.on(:control)
    assert_equal error_message_from_model(@control_objective_item,
      :auditor_comment, :blank), @control_objective_item.errors.on(
      :auditor_comment)

    @control_objective_item.pre_audit_qualification = 0

    assert !@control_objective_item.valid?
    assert_equal 6, @control_objective_item.errors.count
    assert_nil @control_objective_item.errors.on(:post_audit_qualification)
    assert_equal error_message_from_model(@control_objective_item.controls[0],
      :design_tests, :blank), @control_objective_item.controls[0].errors.on(
      :design_tests)
  end

  test 'effectiveness with pre audit qualification' do
    qualifications = @control_objective_item.get_parameter(
      :admin_control_objective_qualifications)
    high_qualification_value = qualifications.map { |item| item[1].to_i }.max

    @control_objective_item.post_audit_qualification =
      high_qualification_value - 1
    @control_objective_item.pre_audit_qualification = 0

    # La calificación de post sólo participa en el 50% del cálculo de
    # efectividad
    assert_equal (high_qualification_value - 1) * 50 /
      high_qualification_value, @control_objective_item.effectiveness
  end

  test 'must be approved' do
    assert @control_objective_item.finished?
    assert_not_nil @control_objective_item.post_audit_qualification
    assert @control_objective_item.relevance > 0

    assert @control_objective_item.must_be_approved?
    assert @control_objective_item.approval_errors.blank?

    @control_objective_item.relevance = 0
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.post_audit_qualification = nil
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.finished = false
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.controls[0].effects = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.controls[0].control = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.controls[0].compliance_tests = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.auditor_comment = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    assert @control_objective_item.pre_audit_qualification
    @control_objective_item.controls[0].design_tests = '  '
    assert !@control_objective_item.must_be_approved?
    assert_equal 1, @control_objective_item.approval_errors.size

    @control_objective_item.reload
    @control_objective_item.pre_audit_qualification = nil
    @control_objective_item.controls[0].design_tests = '  '
    assert @control_objective_item.must_be_approved?
    assert @control_objective_item.approval_errors.blank?

    assert @control_objective_item.reload.must_be_approved?
    assert @control_objective_item.approval_errors.blank?
  end

  test 'can be modified' do
    uneditable_control_objective_item = ControlObjectiveItem.find(
      control_objective_items(
        :bcra_A4609_security_management_responsible_dependency_item).id)

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
      control_objective_items(
        :bcra_A4609_security_management_responsible_dependency_item).id)

    assert_no_difference 'ControlObjectiveItem.count' do
      assert_difference 'WorkPaper.count' do
        uneditable_control_objective_item.update_attributes({
        :post_audit_work_papers_attributes => {
            '1_new' => {
              :name => 'New post_workpaper name',
              :code => 'PTOC 20',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {
                :uploaded_data => ActionController::TestUploadedFile.new(
                  TEST_FILE, 'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'work papers can not be added to uneditable and closed control objectives' do
    uneditable_control_objective_item = ControlObjectiveItem.find(
      control_objective_items(:iso_27000_security_policy_3_1_item).id)

    assert_no_difference ['ControlObjectiveItem.count', 'WorkPaper.count'] do
      assert_raise(RuntimeError) do
        uneditable_control_objective_item.update_attributes({
        :post_audit_work_papers_attributes => {
            '1_new' => {
              :name => 'New post_workpaper name',
              :code => 'New post_workpaper code',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {
                :uploaded_data => ActionController::TestUploadedFile.new(
                  TEST_FILE, 'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'to pdf' do
    assert !File.exist?(@control_objective_item.absolute_pdf_path)

    assert_nothing_raised(Exception) do
      @control_objective_item.to_pdf(organizations(:default_organization))
    end

    assert File.exist?(@control_objective_item.absolute_pdf_path)
    assert File.size(@control_objective_item.absolute_pdf_path) > 0

    FileUtils.rm @control_objective_item.absolute_pdf_path
  end
end