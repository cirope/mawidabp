require 'test_helper'

# Clase para probar el modelo "ConclusionReview"
class ConclusionReviewTest < ActiveSupport::TestCase
  fixtures :conclusion_reviews

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @conclusion_review = ConclusionReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ConclusionReview, @conclusion_review
    fixture_conclusion_review =
      conclusion_reviews(:conclusion_past_final_review)
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

  # Prueba la creación de un informe de conclusión
  test 'create' do
    assert_difference 'ConclusionReview.count' do
      @conclusion_review = ConclusionFinalReview.new({
        :review => reviews(:review_approved_with_conclusion),
        :issue_date => Date.today,
        :close_date => 2.days.from_now.to_date,
        :applied_procedures => 'New applied procedures',
        :conclusion => 'New conclusion'
      }, {}, false)

      assert @conclusion_review.save
    end
  end

  # Prueba de actualización de un informe de conclusión
  test 'update' do
    @conclusion_review = ConclusionReview.find(
      conclusion_reviews(:conclusion_past_draft_review).id)
    assert @conclusion_review.update(
      :applied_procedures => 'Updated applied procedures'),
      @conclusion_review.errors.full_messages.join('; ')
    @conclusion_review.reload
    assert_equal 'Updated applied procedures',
      @conclusion_review.applied_procedures
  end

  # Prueba de eliminación de informes de conclusión
  test 'destroy' do
    assert_no_difference 'ConclusionReview.count' do
      @conclusion_review.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @conclusion_review.issue_date = nil
    @conclusion_review.review_id = nil
    @conclusion_review.applied_procedures = '   '
    @conclusion_review.conclusion = '   '
    assert @conclusion_review.invalid?
    assert_equal 4, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :issue_date,
      :blank)], @conclusion_review.errors[:issue_date]
    assert_equal [error_message_from_model(@conclusion_review, :review_id,
      :blank)], @conclusion_review.errors[:review_id]
    assert_equal [error_message_from_model(@conclusion_review,
      :applied_procedures, :blank)],
      @conclusion_review.errors[:applied_procedures]
    assert_equal [error_message_from_model(@conclusion_review, :conclusion,
      :blank)], @conclusion_review.errors[:conclusion]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @conclusion_review.type = 'abcdd' * 52
    assert @conclusion_review.invalid?
    assert_equal 1, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :type, :too_long,
      :count => 255)], @conclusion_review.errors[:type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @conclusion_review = ConclusionFinalReview.new({
        :review => reviews(:review_with_conclusion),
        :issue_date => '13/13/13',
        :close_date => '13/13/13',
        :applied_procedures => 'New applied procedures',
        :conclusion => 'New conclusion'
      }, {}, false)

    assert @conclusion_review.invalid?
    assert_equal 3, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :issue_date,
      :blank)], @conclusion_review.errors[:issue_date]
    assert_equal [error_message_from_model(@conclusion_review, :close_date,
      :blank), error_message_from_model(@conclusion_review, :close_date,
      :invalid_date)].sort, @conclusion_review.errors[:close_date].sort
  end

  test 'validates date attributes between boundaries' do
    @conclusion_review = ConclusionFinalReview.new({
        :review => reviews(:review_with_conclusion),
        :issue_date => Date.today,
        :close_date => 2.days.ago.to_date,
        :applied_procedures => 'New applied procedures',
        :conclusion => 'New conclusion'
      }, {}, false)

    assert @conclusion_review.invalid?
    assert_equal 1, @conclusion_review.errors.count
    assert_equal [error_message_from_model(@conclusion_review, :close_date,
      :on_or_after, :restriction => I18n.l(Date.today))],
      @conclusion_review.errors[:close_date]
  end

  test 'send by email' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    user = User.find users(:administrator_user).id

    assert_difference 'ActionMailer::Base.deliveries.size' do
      @conclusion_review.send_by_email_to(user)
    end
  end

  test 'pdf conversion' do
    assert_nothing_raised(Exception) do
      @conclusion_review.to_pdf(organizations(:default_organization))
    end

    assert File.exist?(@conclusion_review.absolute_pdf_path)
    assert (size = File.size(@conclusion_review.absolute_pdf_path)) > 0

    FileUtils.rm @conclusion_review.absolute_pdf_path

    assert_nothing_raised(Exception) do
      @conclusion_review.to_pdf(
        organizations(:default_organization), :hide_score => true
      )
    end

    assert File.exist?(@conclusion_review.absolute_pdf_path)
    assert (new_size = File.size(@conclusion_review.absolute_pdf_path)) > 0
    assert_not_equal size, new_size

    assert_nothing_raised(Exception) do
      @conclusion_review.to_pdf(
        organizations(:default_organization),
        :hide_control_objectives_excluded_from_score => '1'
      )
    end

    assert File.exist?(@conclusion_review.absolute_pdf_path)
    assert (new_size = File.size(@conclusion_review.absolute_pdf_path)) > 0
    assert_not_equal size, new_size
  end

  test 'create bundle zip' do
    if File.exist?(@conclusion_review.absolute_bundle_zip_path)
      FileUtils.rm @conclusion_review.absolute_bundle_zip_path
    end

    assert !File.exist?(@conclusion_review.absolute_bundle_zip_path)

    assert_nothing_raised(Exception) do
      @conclusion_review.create_bundle_zip(organizations(:default_organization),
        "one\ntwo")
    end

    assert File.exist?(@conclusion_review.absolute_bundle_zip_path)
    assert File.size(@conclusion_review.absolute_bundle_zip_path) > 0

    FileUtils.rm @conclusion_review.absolute_bundle_zip_path
  end

  test 'bundle index pdf' do
    if File.exist?(@conclusion_review.absolute_bundle_index_pdf_path)
      FileUtils.rm @conclusion_review.absolute_bundle_index_pdf_path
    end

    assert !File.exist?(@conclusion_review.absolute_bundle_index_pdf_path)

    assert_nothing_raised(Exception) do
      @conclusion_review.bundle_index_pdf(organizations(:default_organization),
        "one\ntwo")
    end

    assert File.exist?(@conclusion_review.absolute_bundle_index_pdf_path)
    assert File.size(@conclusion_review.absolute_bundle_index_pdf_path) > 0

    FileUtils.rm @conclusion_review.absolute_bundle_index_pdf_path
  end

  test 'create cover pdf' do
    if File.exist?(@conclusion_review.absolute_cover_pdf_path('test.pdf'))
        FileUtils.rm @conclusion_review.absolute_cover_pdf_path('test.pdf')
    end

    assert !File.exist?(@conclusion_review.absolute_cover_pdf_path('test.pdf'))

    assert_nothing_raised(Exception) do
      @conclusion_review.create_cover_pdf(Organization.find(organizations(
            :default_organization).id), 'test text', 'test.pdf')
    end

    assert File.exist?(@conclusion_review.absolute_cover_pdf_path('test.pdf'))
    assert File.size(@conclusion_review.absolute_cover_pdf_path('test.pdf')) > 0

    FileUtils.rm @conclusion_review.absolute_cover_pdf_path('test.pdf')
  end

  test 'create workflow pdf' do
    assert !File.exist?(@conclusion_review.absolute_workflow_pdf_path)

    assert_nothing_raised(Exception) do
      @conclusion_review.create_workflow_pdf(organizations(
          :default_organization))
    end

    assert File.exist?(@conclusion_review.absolute_workflow_pdf_path)
    assert File.size(@conclusion_review.absolute_workflow_pdf_path) > 0

    FileUtils.rm @conclusion_review.absolute_workflow_pdf_path
  end

  test 'create findings sheet pdf' do
    conclusion_review = ConclusionReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)
    assert !File.exist?(conclusion_review.absolute_findings_sheet_pdf_path)

    assert_nothing_raised(Exception) do
      conclusion_review.create_findings_sheet_pdf(organizations(
          :default_organization))
    end

    assert File.exist?(conclusion_review.absolute_findings_sheet_pdf_path)
    assert File.size(conclusion_review.absolute_findings_sheet_pdf_path) > 0

    FileUtils.rm conclusion_review.absolute_findings_sheet_pdf_path
  end

  test 'create findings follow up pdf' do
    conclusion_review = ConclusionReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)
    file_path = conclusion_review.absolute_findings_follow_up_pdf_path

    assert !File.exist?(file_path)

    assert_nothing_raised(Exception) do
      conclusion_review.create_findings_follow_up_pdf(organizations(
          :default_organization))
    end

    assert File.exist?(file_path)
    assert File.size(file_path) > 0

    FileUtils.rm file_path
  end
end
