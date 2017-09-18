require 'test_helper'

# Clase para probar el modelo "Review"
class ReviewTest < ActiveSupport::TestCase
  fixtures :reviews, :periods, :plan_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @review = Review.find reviews(:review_with_conclusion).id

    set_organization
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Review, @review
    assert_equal reviews(:review_with_conclusion).identification,
      @review.identification
    assert_equal reviews(:review_with_conclusion).description,
      @review.description
  end

  # Prueba la creación de un reporte
  test 'create' do
    assert_difference 'Review.count' do
      @review = Review.list.create(
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
              :user => users(:supervisor_second_user)
            },
            :new_4 => {
              :assignment_type => ReviewUserAssignment::TYPES[:audited],
              :user => users(:audited_user)
            }
          }
      )
    end

    assert @review.score > 0
    assert @review.achieved_scale > 0
    assert @review.top_scale > 0
  end

  # Prueba de actualización de un reporte
  test 'update' do
    assert @review.update(:description => 'New description'),
      @review.errors.full_messages.join('; ')
    @review.reload
    assert_equal 'New description', @review.description
  end

  # Prueba de eliminación de un reporte
  test 'destroy' do
    assert_no_difference('Review.count') { @review.destroy }

    review = reviews(:review_without_conclusion_and_without_findings)

    assert_difference('Review.count', -1) { review.destroy }
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
    assert_error @review, :identification, :blank
    assert_error @review, :description, :blank
    assert_error @review, :period_id, :blank
    assert_error @review, :plan_item_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @review.identification = 'abcdd' * 52

    assert @review.invalid?
    assert_error @review, :identification, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @review.identification = '?nil'

    assert @review.invalid?
    assert_error @review, :identification, :invalid
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @review.identification = reviews(:past_review).identification
    @review.plan_item_id = reviews(:past_review).plan_item_id

    assert @review.invalid?
    assert_error @review, :identification, :taken
    assert_error @review, :plan_item_id, :taken

    @review.period_id = periods(:current_period_google).id
    @review.period.reload

    assert @review.invalid?
    assert_error @review, :plan_item_id, :taken
  end

  test 'validates valid attributes' do
    @review.plan_item_id = plan_items(
      :current_plan_item_4_without_business_unit).id

    assert @review.invalid?
    assert_error @review, :plan_item_id, :invalid
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
    assert !@review.control_objective_items_for_score.empty?

    cois_count = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.relevance
    end
    total = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end

    average = (total / cois_count.to_f).round

    scores = Review.scores.to_a
    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }
    count = scores.size + 1

    assert_equal average, @review.score_array.last
    assert_equal average, @review.score
    assert !@review.reload.score_text.blank?
    assert(scores.any? { |s| count -= 1; s[0] == @review.score_array.first })
    assert count > 0
    assert_equal count, @review.achieved_scale
    assert scores.size > 0
    assert_equal scores.size, @review.top_scale

    assert_difference '@review.control_objective_items_for_score.size', -1 do
      @review.control_objective_items.first.exclude_from_score = true
    end

    assert !@review.control_objective_items_for_score.empty?

    cois_count = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.relevance
    end
    total = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end

    new_average = (total / cois_count.to_f).round
    assert_not_equal average, new_average
  end

  test 'must be approved function' do
    @review = reviews(:review_approved_with_conclusion)

    assert @review.must_be_approved?
    assert @review.approval_errors.blank?

    review_weakness = @review.weaknesses.first
    finding = Weakness.new review_weakness.dup.attributes.merge(
      'state' => Finding::STATUS[:implemented_audited],
      'review_code' => @review.next_weakness_code('O')
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    finding.solution_date = nil

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    def finding.can_be_destroyed?; true; end
    assert finding.destroy

    finding = Weakness.new(
      finding.attributes.merge(
        'state' => Finding::STATUS[:implemented],
        'solution_date' => Date.today,
        'follow_up_date' => nil
      )
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    def finding.can_be_destroyed?; true; end
    assert finding.destroy

    finding = Weakness.new finding.attributes.merge(
        'state' => Finding::STATUS[:being_implemented]
      )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?
    def finding.can_be_destroyed?; true; end
    assert finding.destroy

    Finding.current_user = users :supervisor_user

    finding = Weakness.new finding.attributes.merge(
      'state' => Finding::STATUS[:assumed_risk]
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save

    Finding.current_user = nil

    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?
    def finding.can_be_destroyed?; true; end
    assert finding.destroy

    finding = Weakness.new finding.attributes.merge(
      'state' => Finding::STATUS[:unconfirmed],
      'follow_up_date' => nil,
      'solution_date' => nil
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save, finding.errors.full_messages.join('; ')

    assert !@review.reload.must_be_approved?
    assert_equal 2, @review.approval_errors.size
    assert !@review.can_be_approved_by_force
    def finding.can_be_destroyed?; true; end
    assert finding.destroy

    finding = Weakness.new finding.attributes.merge(
      'state' => Finding::STATUS[:being_implemented],
      'follow_up_date' => Date.today,
      'solution_date' => Date.today
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    # La debilidad tiene una fecha de solución
    assert !@review.reload.must_be_approved?
    assert !@review.approval_errors.blank?

    assert finding.update_attribute(:solution_date, nil)
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

    assert @review.control_objective_items.where(
      :finished => false
    ).first.update_attribute(:finished, true)
    assert @review.reload.must_be_approved?

    assert @review.finding_review_assignments.build(
      :finding_id => findings(:being_implemented_weakness).id
    )
    assert !@review.must_be_approved?
    assert @review.approval_errors.flatten.include?(
      I18n.t('review.errors.related_finding_incomplete'))

    assert @review.reload.must_be_approved?

    review = reviews(:review_without_conclusion_and_without_findings)

    review.control_objective_items.clear

    assert !review.must_be_approved?
    assert review.approval_errors.flatten.include?(
      I18n.t('review.errors.without_control_objectives')
    )
  end

  test 'can be sended' do
    @review = reviews(:review_approved_with_conclusion)

    assert @review.can_be_sended?

    review_weakness = @review.control_objective_items.first.weaknesses.first
    finding = Weakness.new review_weakness.dup.attributes.merge(
        'state' => Finding::STATUS[:implemented_audited],
        'review_code' => @review.next_weakness_code('O')
      )
    finding.finding_user_assignments.build clone_finding_user_assignments(
      review_weakness)

    finding.solution_date = nil

    assert finding.save(:validate => false) # Forzado para que no se validen los datos
    assert !@review.reload.can_be_sended?
  end

  test 'has audited function' do
    assert @review.has_audited?
    assert @review.valid?

    @review.review_user_assignments.delete_all(&:audited?)

    assert !@review.has_audited?
    assert @review.invalid?
  end

  test 'has manager or supervisor function' do
    assert @review.has_manager? || @review.has_supervisor?
    assert @review.valid?

    @review.review_user_assignments.delete_all { |a| a.manager? || a.supervisor? }

    assert !@review.has_supervisor? && !@review.has_manager?
    assert @review.invalid?
  end

  test 'has auditor function' do
    assert @review.has_auditor?
    assert @review.valid?

    @review.review_user_assignments.delete_all(&:auditor?)

    assert !@review.has_auditor?
    assert @review.invalid?
  end

  test 'process control ids' do
    assert @review.control_objective_items.present?
    assert_difference '@review.control_objective_items.size', 5 do
      @review.process_control_ids = [process_controls(:iso_27000_security_policy).id]
    end

    assert_no_difference '@review.control_objective_items.size' do
      @review.process_control_ids = [process_controls(:iso_27000_security_policy).id]
    end
  end

  test 'procedure control subitem ids' do
    assert @review.control_objective_items.present?
    assert_difference '@review.control_objective_items.size' do
      @review.control_objective_ids = [control_objectives(:iso_27000_security_organization_4_1).id]
    end

    assert_no_difference '@review.control_objective_items.size' do
      @review.control_objective_ids = [control_objectives(:iso_27000_security_organization_4_1).id]
    end
  end

  test 'add a related finding from a final review' do
    assert_difference '@review.finding_review_assignments.count' do
      assert @review.update(
        :finding_review_assignments_attributes => {
          :new_1 => {
            :finding_id => findings(:unanswered_weakness).id.to_s
          }
        }
      )
    end
  end

  test 'can not add a related finding without a final review' do
    assert_no_difference '@review.finding_review_assignments.count' do
      assert_raise RuntimeError do
        @review.update(
          :finding_review_assignments_attributes => {
            :new_1 => {
              :finding_id => findings(:confirmed_oportunity_on_draft).id.to_s
            }
          }
        )
      end
    end
  end

  test 'effectiveness function' do
    coi_count = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.relevance
    end

    total = @review.control_objective_items_for_score.inject(0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance
    end

    assert total > 0
    assert_equal (total / coi_count.to_f).round, @review.effectiveness
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

    assert_equal "#{weakness_prefix}#{'%.3d' % weakness_number.next}",
      @review.reload.next_weakness_code(weakness_prefix)
    assert_equal 'New prefix001',
      @review.reload.next_weakness_code('New prefix')
  end

  test 'last oportunity code' do
    generated_code = @review.next_oportunity_code('pre')
    finding = @review.oportunities.sort_by_code.last
    oportunity_number = finding.review_code.match(/\d+\Z/)[0].to_i
    oportunity_prefix = finding.review_code.sub(/\d+\Z/, '')

    assert_match /\Apre\d+\Z/, generated_code

    assert_equal "#{oportunity_prefix}#{'%.3d' % oportunity_number.next}",
      @review.reload.next_oportunity_code(oportunity_prefix)
    assert_equal 'New prefix001',
      @review.reload.next_oportunity_code('New prefix')
  end

  test 'score sheet pdf' do
    assert_nothing_raised do
      @review.score_sheet(organizations(:cirope))
    end

    assert File.exist?(@review.absolute_score_sheet_path)
    assert File.size(@review.absolute_score_sheet_path) > 0

    FileUtils.rm @review.absolute_score_sheet_path
  end

  test 'global score sheet pdf' do
    assert_nothing_raised do
      @review.global_score_sheet(organizations(:cirope))
    end

    assert File.exist?(@review.absolute_global_score_sheet_path)
    assert File.size(@review.absolute_global_score_sheet_path) > 0

    FileUtils.rm @review.absolute_global_score_sheet_path
  end

  test 'zip all work papers' do
    assert_nothing_raised do
      @review.zip_all_work_papers
    end

    assert File.exist?(@review.absolute_work_papers_zip_path)
    assert File.size(@review.absolute_work_papers_zip_path) > 0

    FileUtils.rm @review.absolute_work_papers_zip_path
  end

  test 'clone from' do
    new_review = Review.new
    new_review.clone_from(@review)

    assert new_review.control_objective_items.size > 0
    assert new_review.review_user_assignments.size > 0
    assert_equal @review.control_objective_items.map(&:control_objective_id).sort,
      new_review.control_objective_items.map(&:control_objective_id).sort
    assert_equal(
      @review.review_user_assignments.map { |a| [a.assignment_type, a.user_id] },
      new_review.review_user_assignments.map { |a| [a.assignment_type, a.user_id] }
    )
  end

  test 'recode findings' do
    codes = @review.weaknesses.not_revoked.pluck 'review_code'

    assert codes.each_with_index.any? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i != i.next
    }

    @review.recode_weaknesses

    codes = @review.reload.weaknesses.not_revoked.pluck 'review_code'

    assert codes.sort.each_with_index.all? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i == i.next
    }
  end

  private

    def clone_finding_user_assignments(finding)
      finding.finding_user_assignments.map do |fua|
        fua.dup.attributes.merge('finding_id' => nil)
      end
    end
end
