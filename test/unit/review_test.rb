require 'test_helper'

# Clase para probar el modelo "Review"
class ReviewTest < ActiveSupport::TestCase
  fixtures :reviews, :periods, :plan_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @review = Review.find reviews(:review_with_conclusion).id
    GlobalModelConfig.current_organization_id = organizations(
      :default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Review, @review
    assert_equal reviews(:review_with_conclusion).identification, @review.identification
    assert_equal reviews(:review_with_conclusion).description, @review.description
  end

  # Prueba la creación de un reporte
  test 'create' do
    assert_difference 'Review.count' do
      @review = Review.create(
        :identification => 'New Identification',
        :description => 'New Description',
        :period_id => periods(:current_period).id,
        :plan_item_id => plan_items(:past_plan_item_3).id,
        :review_user_assignments_attributes => {
            :new_1 => {
              :assignment_type => ReviewUserAssignment::TYPES[:auditor],
              :user => users(:first_time_user)
            },
            :new_2 => {
              :assignment_type => ReviewUserAssignment::TYPES[:supervisor],
              :user => users(:supervisor_user)
            },
            :new_3 => {
              :assignment_type => ReviewUserAssignment::TYPES[:manager],
              :user => users(:manager_user)
            },
            :new_4 => {
              :assignment_type => ReviewUserAssignment::TYPES[:audited],
              :user => users(:audited_user)
            }
          }
      )
    end
  end

  # Prueba de actualización de un reporte
  test 'update' do
    assert @review.update_attributes(:description => 'New description'),
      @review.errors.full_messages.join('; ')
    @review.reload
    assert_equal 'New description', @review.description
  end

  # Prueba de eliminación de un reporte
  test 'destroy' do
    assert_difference('Review.count', -1) { @review.destroy }
  end

  test 'destroy with final review' do
    assert_no_difference 'Review.count' do
      Review.find(reviews(:current_review).id).destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @review.identification = nil
    @review.description = '   '
    @review.period_id = nil
    @review.plan_item_id = nil
    assert @review.invalid?
    assert_equal 4, @review.errors.count
    assert_equal error_message_from_model(@review, :identification, :blank),
      @review.errors.on(:identification)
    assert_equal error_message_from_model(@review, :description, :blank),
      @review.errors.on(:description)
    assert_equal error_message_from_model(@review, :period_id, :blank),
      @review.errors.on(:period_id)
    assert_equal error_message_from_model(@review, :plan_item_id, :blank),
      @review.errors.on(:plan_item_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @review.identification = 'abcdd' * 52
    assert @review.invalid?
    assert_equal 1, @review.errors.count
    assert_equal error_message_from_model(@review, :identification, :too_long,
      :count => 255), @review.errors.on(:identification)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @review.identification = '?nil'
    @review.period_id = '12.3'
    @review.plan_item_id = '?nil'
    assert @review.invalid?
    assert_equal 3, @review.errors.count
    assert_equal error_message_from_model(@review, :identification, :invalid),
      @review.errors.on(:identification)
    assert_equal error_message_from_model(@review, :period_id, :not_a_number),
      @review.errors.on(:period_id)
    assert_equal error_message_from_model(@review, :plan_item_id,
      :not_a_number), @review.errors.on(:plan_item_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @review.identification = reviews(:past_review).identification
    @review.plan_item_id = reviews(:past_review).plan_item_id
    assert @review.invalid?
    assert_equal 2, @review.errors.count
    assert_equal error_message_from_model(@review, :identification, :taken),
      @review.errors.on(:identification)
    assert_equal error_message_from_model(@review, :plan_item_id, :taken),
      @review.errors.on(:plan_item_id)
  end

  test 'validates valid attributes' do
    @review.plan_item_id = plan_items(
      :current_plan_item_4_without_business_unit).id

    assert @review.invalid?
    assert_equal 1, @review.errors.count
    assert_equal error_message_from_model(@review, :plan_item, :invalid),
      @review.errors.on(:plan_item)
  end

  test 'can be modified' do
    uneditable_review = Review.find(reviews(:current_review).id)

    @review.description = 'Updated description'

    assert !@review.has_final_review?
    assert @review.can_be_modified?

    assert uneditable_review.has_final_review?

    # Puede ser "modificado" porque no se ha actualizado ninguno de sus
    # atributos
    assert uneditable_review.can_be_modified?

    uneditable_review.description = 'Updated description'

    # No puede ser actualizado porque se ha modificado un atributo
    assert !uneditable_review.can_be_modified?
    assert !uneditable_review.save

    assert_no_difference 'Review.count' do
      uneditable_review.destroy
    end
  end

  test 'review score' do
    assert !@review.control_objective_items.empty?

    cois_count = @review.control_objective_items.inject(0) do |acc, coi|
      acc + coi.relevance
    end
    total = @review.control_objective_items.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end
    
    average = (total / cois_count).round

    assert_equal average, @review.score.last
    assert !@review.score_text.blank?
    assert(get_test_parameter(:admin_review_scores).any? do |s|
        s[0] == @review.score.first
      end)
  end

  test 'must be approved function' do
    assert @review.must_be_approved?
    assert @review.approval_errors.blank?

    review_weakness = @review.control_objective_items.first.weaknesses.first
    oportunity = Weakness.new review_weakness.attributes.merge({
        :state => Finding::STATUS[:implemented_audited],
        :review_code => @review.next_weakness_code('O')})
    oportunity.user_ids = review_weakness.user_ids

    oportunity.solution_date = nil

    assert oportunity.save(false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    assert oportunity.destroy

    oportunity = Weakness.new oportunity.attributes.merge({
        :state => Finding::STATUS[:implemented],
        :solution_date => Time.now.to_date, :follow_up_date => nil})
    oportunity.user_ids = review_weakness.user_ids

    assert oportunity.save(false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    assert oportunity.destroy

    oportunity = Weakness.new oportunity.attributes.merge({
        :state => Finding::STATUS[:being_implemented]})
    oportunity.user_ids = review_weakness.user_ids

    assert oportunity.save(false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    assert oportunity.destroy

    oportunity = Weakness.new oportunity.attributes.merge({
        :state => Finding::STATUS[:assumed_risk]})
    oportunity.user_ids = review_weakness.user_ids

    assert oportunity.save
    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?
    assert oportunity.destroy

    oportunity = Weakness.new oportunity.attributes.merge({
        :state => Finding::STATUS[:being_implemented],
        :follow_up_date => Time.now.to_date})
    oportunity.user_ids = review_weakness.user_ids

    assert oportunity.save(false) # Forzado para que no se validen los datos
    # La debilidad tiene una fecha de solución
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?

    assert oportunity.update_attribute(:solution_date, nil)
    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?

    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?
    @review.survey = ''
    assert !@review.must_be_approved?
    assert !@review.approval_errors.blank?

    assert @review.control_objective_items.first.update_attribute(
      :finished, false)
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
  end

  test 'must be approved function with notifications' do
    assert @review.must_be_approved?

    @review.conclusion_draft_review.notification_relations.create(
      :model => @conclusion_review,
      :notification => Notification.new(
        :user => users(:administrator_user)
      )
    )

    assert @review.is_approved?

    assert @review.conclusion_draft_review.notifications(true).first.notify!(
      false)

    assert !@review.is_approved?
    assert !@review.approval_errors.blank?

    # Ahora el mismo usuario crea confirma una nueva notificación
    @review.conclusion_draft_review.notification_relations.create(
      :model => @conclusion_review,
      :notification => Notification.new(
        :user => users(:administrator_user)
      )
    )

    assert @review.conclusion_draft_review.notifications(true).first.notify!(
      true)

    assert @review.is_approved?
  end

  test 'can be sended' do
    assert @review.can_be_sended?

    notification_relation = @review.conclusion_draft_review.
      notification_relations.create(
      :model => @conclusion_review,
      :notification => Notification.new(
        :user => users(:administrator_user)
      )
    )

    assert !@review.reload.can_be_sended?

    assert notification_relation.notification.notify!(false)

    assert @review.reload.can_be_sended?

    # Ahora el mismo usuario crea confirma una nueva notificación
    @review.conclusion_draft_review.notification_relations.create(
      :model => @conclusion_review,
      :notification => Notification.new(
        :user => users(:administrator_user)
      )
    )

    assert notification_relation.notification.notify!(true)
    
    assert !@review.reload.can_be_sended?
  end

  test 'has audited function' do
    assert @review.has_audited?
    assert @review.valid?

    audited = @review.review_user_assignments.select { |rua| rua.audited? }
    @review.review_user_assignments.delete audited

    assert !@review.has_audited?
    assert @review.invalid?
  end

  test 'has manager function' do
    assert @review.has_manager?
    assert @review.valid?

    managers = @review.review_user_assignments.select { |rua| rua.manager? }
    @review.review_user_assignments.delete managers

    assert !@review.has_manager?
    assert @review.invalid?
  end

  test 'has auditor function' do
    assert @review.has_auditor?
    assert @review.valid?

    auditors = @review.review_user_assignments.select { |rua| rua.auditor? }
    @review.review_user_assignments.delete auditors

    assert !@review.has_auditor?
    assert @review.invalid?
  end

  test 'has supervisor function' do
    assert @review.has_supervisor?
    assert @review.valid?

    supervisors = @review.review_user_assignments.select {|rua| rua.supervisor?}
    @review.review_user_assignments.delete supervisors

    assert !@review.has_supervisor?
    assert @review.invalid?
  end

  test 'procedure control subitem ids' do
    assert !@review.control_objective_items.empty?
    assert_difference '@review.control_objective_items.size' do
      @review.procedure_control_subitem_ids =
        [procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1).id]
    end

    assert_no_difference '@review.control_objective_items.size' do
      @review.procedure_control_subitem_ids =
        [procedure_control_subitems(:procedure_control_subitem_bcra_A4609_1_1).id]
    end
  end

  test 'effectiveness function' do
    coi_count = @review.control_objective_items.inject(0) do |acc, coi|
      acc + coi.relevance
    end

    total = @review.control_objective_items.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end

    assert total > 0
    assert_equal (total / coi_count).round, @review.effectiveness
  end

  test 'last control objective work paper code' do
    generated_code = @review.last_control_objective_work_paper_code('pre')

    assert_match /\Apre\s\d+\Z/, generated_code

    assert_equal 'New prefix 00',
      @review.reload.last_control_objective_work_paper_code('New prefix')
  end

  test 'last weakness work paper code' do
    generated_code = @review.last_weakness_work_paper_code('pre')

    assert_match /\Apre\s\d+\Z/, generated_code
    
    assert_equal 'New prefix 00',
      @review.reload.last_weakness_work_paper_code('New prefix')
  end

  test 'last oportunity work paper code' do
    generated_code = @review.last_oportunity_work_paper_code('pre')

    assert_match /\Apre\s\d+\Z/, generated_code

    assert_equal 'New prefix 00',
      @review.reload.last_oportunity_work_paper_code('New prefix')
  end

  test 'last weakness code' do
    generated_code = @review.next_weakness_code('pre')
    weakness = @review.weaknesses.sort_by_code.last
    weakness_number = weakness.review_code.match(/\d+\Z/)[0].to_i
    weakness_prefix = weakness.review_code.sub(/\d+\Z/, '')

    assert_match /\Apre\d+\Z/, generated_code

    assert_equal "#{weakness_prefix}#{'%.2d' % weakness_number.next}",
      @review.reload.next_weakness_code(weakness_prefix)
    assert_equal 'New prefix01',
      @review.reload.next_weakness_code('New prefix')
  end

  test 'last oportunity code' do
    generated_code = @review.next_oportunity_code('pre')
    oportunity = @review.oportunities.sort_by_code.last
    oportunity_number = oportunity.review_code.match(/\d+\Z/)[0].to_i
    oportunity_prefix = oportunity.review_code.sub(/\d+\Z/, '')

    assert_match /\Apre\d+\Z/, generated_code

    assert_equal "#{oportunity_prefix}#{'%.2d' % oportunity_number.next}",
      @review.reload.next_oportunity_code(oportunity_prefix)
    assert_equal 'New prefix01',
      @review.reload.next_oportunity_code('New prefix')
  end

  test 'score sheet pdf' do
    assert_nothing_raised(Exception) do
      @review.score_sheet(organizations(:default_organization))
    end

    assert File.exist?(@review.absolute_score_sheet_path)
    assert File.size(@review.absolute_score_sheet_path) > 0

    FileUtils.rm @review.absolute_score_sheet_path
  end

  test 'global score sheet pdf' do
    assert_nothing_raised(Exception) do
      @review.global_score_sheet(organizations(:default_organization))
    end

    assert File.exist?(@review.absolute_global_score_sheet_path)
    assert File.size(@review.absolute_global_score_sheet_path) > 0

    FileUtils.rm @review.absolute_global_score_sheet_path
  end

  test 'zip all work papers' do
    assert_nothing_raised(Exception) do
      @review.zip_all_work_papers
    end

    assert File.exist?(@review.absolute_work_papers_zip_path)
    assert File.size(@review.absolute_work_papers_zip_path) > 0

    FileUtils.rm @review.absolute_work_papers_zip_path
  end
end