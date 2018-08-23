require 'test_helper'

# Clase para probar el modelo "Review"
class ReviewTest < ActiveSupport::TestCase
  fixtures :reviews, :periods, :plan_items

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @review = reviews :review_with_conclusion

    set_organization
  end

  teardown do
    Current.organization = nil
    Current.group = nil
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
        :scope => 'committee',
        :risk_exposure => 'high',
        :manual_score => 800,
        :include_sox => 'no',
        :review_user_assignments_attributes => {
            :new_1 => {
              :assignment_type => ReviewUserAssignment::TYPES[:auditor],
              :user => users(:first_time)
            },
            :new_2 => {
              :assignment_type => ReviewUserAssignment::TYPES[:supervisor],
              :user => users(:supervisor)
            },
            :new_3 => {
              :assignment_type => ReviewUserAssignment::TYPES[:manager],
              :user => users(:supervisor_second)
            },
            :new_4 => {
              :assignment_type => ReviewUserAssignment::TYPES[:audited],
              :user => users(:audited)
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

    unless SHOW_REVIEW_AUTOMATIC_IDENTIFICATION
      review = reviews(:review_without_conclusion_and_without_findings)

      assert_difference('Review.count', -1) { review.destroy }
    end
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
    @review.scope = ''
    @review.risk_exposure = ''
    @review.include_sox = ''

    assert @review.invalid?
    assert_error @review, :identification, :blank
    assert_error @review, :description, :blank unless HIDE_REVIEW_DESCRIPTION
    assert_error @review, :period_id, :blank
    assert_error @review, :plan_item_id, :blank

    if SHOW_REVIEW_EXTRA_ATTRIBUTES
      assert_error @review, :scope, :blank
      assert_error @review, :risk_exposure, :blank
      assert_error @review, :include_sox, :blank
    end
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
    review = @review.dup

    assert review.invalid?
    assert_error review, :identification, :taken
    assert_error review, :plan_item_id, :taken
  end

  test 'validate unique identification number' do
    skip unless SHOW_REVIEW_AUTOMATIC_IDENTIFICATION

    last_review = Review.order(:id).last
    review = last_review.dup

    last_review.update_column :identification, 'XX-22/2017'

    review.identification = 'YY-22/2017'

    assert review.invalid?
    assert_error review, :identification, :taken
  end

  test 'validates numeric attributes' do
    skip unless SHOW_REVIEW_EXTRA_ATTRIBUTES

    @review.manual_score = -1

    assert @review.invalid?
    assert_error @review, :manual_score, :greater_than_or_equal_to, count: 0

    @review.manual_score = 1001

    assert @review.invalid?
    assert_error @review, :manual_score, :less_than_or_equal_to, count: 1000
  end

  test 'validates valid attributes' do
    @review.plan_item_id = plan_items(
      :current_plan_item_4_without_business_unit).id

    assert @review.invalid?
    assert_error @review, :plan_item_id, :invalid
  end

  test 'validates required tag' do
    @review.taggings.clear
    @review.business_unit.business_unit_type.update! require_tag: true

    assert @review.invalid?
    assert_error @review, :taggings, :blank
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
    skip if score_type != :effectiveness

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
    assert_equal 'effectiveness', @review.score_type
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

  test 'review score by weaknesses' do
    skip if score_type != :weaknesses

    # With two low risk and not repeated weaknesses
    assert_equal :require_some_improvements, @review.score_array.first
    assert_equal 96, @review.score
    assert_equal 'weaknesses', @review.score_type

    review_weakness = @review.weaknesses.first
    finding = Weakness.new review_weakness.dup.attributes.merge(
      'risk' => ::RISK_TYPES[:high]
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )

    finding.save!(:validate => false)

    # High risk counts 12
    assert_equal :require_some_improvements, @review.reload.score_array.first
    assert_equal 84, @review.score

    repeated_of = findings :being_implemented_weakness
    finding.repeated_of_id = repeated_of.id

    @review.finding_review_assignments.create! finding_id: repeated_of.id

    finding.save!(:validate => false)

    # High risk and repeated counts 20
    assert_equal :require_improvements, @review.reload.score_array.first
    assert_equal 76, @review.score

    review = Review.new

    assert_equal :adequate, review.score_array.first
    assert_equal 100, review.score
  end

  test 'must be approved function' do
    @review = reviews(:review_approved_with_conclusion)

    @review.file_model = FileModel.take!
    @review.save!

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

    Current.user = users :supervisor

    finding = Weakness.new finding.attributes.merge(
      'state' => Finding::STATUS[:assumed_risk]
    )
    finding.finding_user_assignments.build(
      clone_finding_user_assignments(review_weakness)
    )
    finding.taggings.build(
      review_weakness.taggings.map do |t|
        t.attributes.dup.merge('id' => nil, 'taggable_id' => nil)
      end
    )

    assert finding.save

    Current.user = nil

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
    finding.taggings.build(
      review_weakness.taggings.map do |t|
        t.attributes.dup.merge('id' => nil, 'taggable_id' => nil)
      end
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

    assert @review.reload.must_be_approved?
    assert @review.approval_errors.blank?

    if SHOW_REVIEW_EXTRA_ATTRIBUTES
      @review.file_model = nil

      refute @review.must_be_approved?
      assert @review.can_be_approved_by_force
      assert @review.approval_errors.flatten.include?(
        I18n.t('review.errors.without_file_model')
      )

      @review.manual_score = nil

      refute @review.must_be_approved?
      refute @review.can_be_approved_by_force
      assert @review.approval_errors.flatten.include?(
        I18n.t('review.errors.without_score')
      )
    end

    @review.review_user_assignments.each { |rua| rua.audited? && rua.delete }
    refute @review.reload.must_be_approved?
    assert @review.approval_errors.present?
    assert @review.approval_errors.flatten.include?(
      I18n.t('review.errors.without_audited')
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

    @review.review_user_assignments.each { |rua| rua.audited? && rua.delete }

    refute @review.reload.has_audited?

    if DISABLE_REVIEW_AUDITED_VALIDATION
      assert @review.valid?
    else
      assert @review.invalid?
    end
  end

  test 'has manager or supervisor function' do
    assert @review.has_manager? || @review.has_supervisor?
    assert @review.valid?

    @review.review_user_assignments.each { |a| (a.manager? || a.supervisor?) && a.delete }

    assert !@review.reload.has_supervisor? && !@review.has_manager?
    assert @review.invalid?
  end

  test 'has auditor function' do
    assert @review.has_auditor?
    assert @review.valid?

    @review.review_user_assignments.each { |rua| rua.auditor? && rua.delete }

    assert !@review.reload.has_auditor?
    assert @review.invalid?
  end

  test 'control objective ids' do
    assert_difference '@review.control_objective_items.size' do
      @review.control_objective_ids = [
        control_objectives(:security_policy_3_1).id
      ]
    end

    if ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION
      assert_difference '@review.control_objective_items.size' do
        @review.control_objective_ids = [
          control_objectives(:security_policy_3_1).id
        ]
      end
    else
      assert_no_difference '@review.control_objective_items.size' do
        @review.control_objective_ids = [
          control_objectives(:security_policy_3_1).id
        ]
      end
    end

    assert_difference '@review.control_objective_items.size' do
      @review.control_objective_ids = [
        control_objectives(:organization_security_4_1).id
      ]
    end
  end

  test 'process control ids' do
    assert @review.control_objective_items.present?
    assert_difference '@review.control_objective_items.size', 5 do
      @review.process_control_ids = [
        process_controls(:security_policy).id
      ]
    end

    if ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION
      assert_difference '@review.control_objective_items.size', 5 do
        @review.process_control_ids = [
          process_controls(:security_policy).id
        ]
      end
    else
      assert_no_difference '@review.control_objective_items.size' do
        @review.process_control_ids = [
          process_controls(:security_policy).id
        ]
      end
    end
  end

  test 'best practice ids' do
    assert @review.control_objective_items.present?

    if ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION
      assert_difference '@review.control_objective_items.size', 2 do
        @review.best_practice_ids = [
          best_practices(:bcra_A4609).id
        ]
      end
    else
      assert_no_difference '@review.control_objective_items.size' do
        @review.best_practice_ids = [
          best_practices(:bcra_A4609).id
        ]
      end
    end
  end

  test 'procedure control subitem ids' do
    assert @review.control_objective_items.present?
    assert_difference '@review.control_objective_items.size' do
      @review.control_objective_ids = [control_objectives(:organization_security_4_1).id]
    end

    if ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION
      assert_difference '@review.control_objective_items.size' do
        @review.control_objective_ids = [control_objectives(:organization_security_4_1).id]
      end
    else
      assert_no_difference '@review.control_objective_items.size' do
        @review.control_objective_ids = [control_objectives(:organization_security_4_1).id]
      end
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
    generated_code = @review.last_control_objective_work_paper_code(prefix: 'pre')

    assert_match /\Apre\s\d+\Z/, generated_code

    assert_equal 'New prefix 000',
      @review.reload.last_control_objective_work_paper_code(prefix: 'New prefix')
  end

  test 'last weakness work paper code' do
    generated_code = @review.last_weakness_work_paper_code(prefix: 'pre')

    assert_match /\Apre\s\d+\Z/, generated_code

    assert_equal 'New prefix 000',
      @review.reload.last_weakness_work_paper_code(prefix: 'New prefix')
  end

  test 'last oportunity work paper code' do
    generated_code = @review.last_oportunity_work_paper_code(prefix: 'pre')

    assert_match /\Apre\s\d+\Z/, generated_code

    assert_equal 'New prefix 000',
      @review.reload.last_oportunity_work_paper_code(prefix: 'New prefix')
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
      @review.zip_all_work_papers @review.organization
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

  test 'recode findings by risk' do
    codes = @review.weaknesses.not_revoked.
      order(risk: :desc, review_code: :asc).pluck 'review_code'

    assert codes.each_with_index.any? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i != i.next
    }

    @review.recode_weaknesses_by_risk

    codes = @review.reload.weaknesses.not_revoked.
      order(risk: :desc, review_code: :asc).pluck 'review_code'

    assert codes.sort.each_with_index.all? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i == i.next
    }
  end

  test 'recode findings by repetition and risk' do
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

    codes = @review.weaknesses.not_revoked.order(order).pluck 'review_code'

    assert codes.each_with_index.any? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i != i.next
    }

    @review.recode_weaknesses_by_repetition_and_risk

    codes = @review.reload.weaknesses.not_revoked.order(order).
      pluck 'review_code'

    assert codes.sort.each_with_index.all? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i == i.next
    }
  end

  test 'recode weaknesses by control objective order' do
    codes = @review.grouped_control_objective_items.map do |_pc, cois|
      cois.map do |coi|
        findings =
          coi.weaknesses.order(risk: :desc, review_code: :asc).not_revoked

        findings.pluck 'review_code'
      end
    end.flatten

    assert codes.each_with_index.any? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i != i.next
    }

    @review.recode_weaknesses_by_control_objective_order

    codes = @review.reload.grouped_control_objective_items.map do |_pc, cois|
      cois.map do |coi|
        findings =
          coi.weaknesses.order(risk: :desc, review_code: :asc).not_revoked

        findings.pluck 'review_code'
      end
    end.flatten

    assert codes.sort.each_with_index.all? { |c, i|
      c.match(/\d+\Z/).to_a.first.to_i == i.next
    }
  end

  test 'next identification number' do
    assert_equal '001', Review.next_identification_number(2017)

    Review.order(:id).last.update_column :identification, 'XX-22/2017'

    # Should ignore the prefix
    assert_equal '023', Review.next_identification_number(2017)
  end

  test 'build best practice comments' do
    expected_count = @review.best_practices.count

    @review.best_practice_comments.destroy_all

    assert expected_count > 0

    assert_difference '@review.best_practice_comments.size', expected_count do
      @review.build_best_practice_comments
    end
  end

  test 'clean stale best practice comments' do
    @review.best_practice_comments.create! auditor_comment: 'Test',
      best_practice_id: best_practices(:iso_27001).id

    assert_difference '@review.best_practice_comments.count', -1 do
      @review.save!
    end
  end

  test 'reorder' do
    @review.control_objective_items.create!(
      order_number: -1,
      control_objective_text: '3.1) Security policy',
      control_objective_id: control_objectives(:security_policy_3_1).id
    )

    pcs        = @review.grouped_control_objective_items.map &:first
    sorted_pcs = pcs.sort_by &:name

    assert_not_equal pcs, sorted_pcs
    assert @review.reorder

    pcs = @review.grouped_control_objective_items.map &:first

    assert_equal pcs, sorted_pcs
  end

  test 'pdf conversion' do
    FileUtils.rm @review.absolute_pdf_path if File.exist?(@review.absolute_pdf_path)

    assert_nothing_raised do
      @review.to_pdf organizations(:cirope)
    end

    assert File.exist?(@review.absolute_pdf_path)
    assert File.size(@review.absolute_pdf_path) > 0

    FileUtils.rm @review.absolute_pdf_path
  end

  private

    def clone_finding_user_assignments(finding)
      finding.finding_user_assignments.map do |fua|
        fua.dup.attributes.merge('finding_id' => nil)
      end
    end

    def score_type
      if SHOW_REVIEW_EXTRA_ATTRIBUTES
        :manual
      elsif ORGANIZATIONS_WITH_REVIEW_SCORE_BY_WEAKNESS.include?(Current.organization.prefix)
        :weaknesses
      else
        :effectiveness
      end
    end
end
