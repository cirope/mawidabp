require 'test_helper'

# Clase para probar el modelo "WorkPaper"
class WorkPaperTest < ActiveSupport::TestCase
  fixtures :work_papers, :file_models, :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @work_paper = WorkPaper.find work_papers(:image_work_paper).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of WorkPaper, @work_paper
    assert_equal work_papers(:image_work_paper).name, @work_paper.name
    assert_equal work_papers(:image_work_paper).code, @work_paper.code
    assert_equal work_papers(:image_work_paper).number_of_pages,
      @work_paper.number_of_pages
    assert_equal work_papers(:image_work_paper).description,
      @work_paper.description
    assert_equal work_papers(:image_work_paper).file_model_id,
      @work_paper.file_model_id
    assert_equal work_papers(:image_work_paper).organization_id,
      @work_paper.organization_id
  end

  # Prueba la creación de un papel de trabajo
  test 'create' do
    assert_difference 'WorkPaper.count' do
      @work_paper = WorkPaper.create(
        :name => 'New name',
        :code => 'PTOC 20',
        :number_of_pages => '10',
        :description => 'New description',
        :organization => organizations(:default_organization),
        :code_prefix => 'PTOC',
        :neighbours => [],
        :file_model_attributes => {
          :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH)
        }
      )
    end
  end

  # Prueba de actualización de un papel de trabajo
  test 'update' do
    assert @work_paper.update_attributes(:name => 'New name'),
      @work_paper.errors.full_messages.join('; ')
    @work_paper.reload
    # Todos los atributos son de solo lectura
    assert_equal 'New name', @work_paper.name
  end

  # Prueba de eliminación de papeles de trabajo
  test 'delete' do
    assert_difference('WorkPaper.count', -1) { @work_paper.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @work_paper.organization_id = nil
    @work_paper.name = '    '
    @work_paper.code = '   '
    @work_paper.number_of_pages = nil
    assert @work_paper.invalid?
    assert_equal 4, @work_paper.errors.count
    assert_equal [error_message_from_model(@work_paper, :organization_id,
        :blank)], @work_paper.errors[:organization_id]
    assert_equal [error_message_from_model(@work_paper, :name, :blank)],
      @work_paper.errors[:name]
    assert_equal [error_message_from_model(@work_paper, :code, :blank)],
      @work_paper.errors[:code]
    assert_equal [error_message_from_model(@work_paper, :number_of_pages,
      :blank)], @work_paper.errors[:number_of_pages]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @work_paper.organization_id = '_124'
    @work_paper.number_of_pages = '12.3'
    assert @work_paper.invalid?
    assert_equal 2, @work_paper.errors.count
    assert_equal [error_message_from_model(@work_paper, :organization_id,
      :not_a_number)], @work_paper.errors[:organization_id]
    assert_equal [error_message_from_model(@work_paper, :number_of_pages,
      :not_an_integer)], @work_paper.errors[:number_of_pages]

    @work_paper.reload
    @work_paper.number_of_pages = '100001'
    assert @work_paper.invalid?
    assert_equal 1, @work_paper.errors.count
    assert_equal [error_message_from_model(@work_paper, :number_of_pages,
      :less_than, :count => 100000)], @work_paper.errors[:number_of_pages]

    @work_paper.reload
    @work_paper.number_of_pages = '0'
    assert @work_paper.invalid?
    assert_equal 1, @work_paper.errors.count
    assert_equal [error_message_from_model(@work_paper, :number_of_pages,
      :greater_than, :count => 0)], @work_paper.errors[:number_of_pages]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @work_paper.name = 'abcdd' * 52
    @work_paper.code = 'abcdd' * 52
    assert @work_paper.invalid?
    assert_equal 2, @work_paper.errors.count
    assert_equal [error_message_from_model(@work_paper, :name, :too_long,
      :count => 255)], @work_paper.errors[:name]
    assert_equal [error_message_from_model(@work_paper, :code, :too_long,
      :count => 255)], @work_paper.errors[:code]
  end

  test 'zip created' do
    assert_difference 'WorkPaper.count' do
      @work_paper = WorkPaper.create(
        :name => 'New name',
        :code => 'PTOC 20',
        :number_of_pages => '10',
        :description => 'New description',
        :organization => organizations(:default_organization),
        :code_prefix => 'PTOC',
        :neighbours => [],
        :file_model_attributes => {
          :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH)
        }
      )
    end

    assert_equal '.zip', File.extname(@work_paper.reload.file_model.file.path)
  end

  test 'duplicated codes' do
    other_work_paper = WorkPaper.find work_papers(:image_work_paper).id

    assert_no_difference 'WorkPaper.count' do
      @work_paper = WorkPaper.create(
        :name => 'New name',
        :code => other_work_paper.code,
        :number_of_pages => '10',
        :description => 'New description',
        :organization => organizations(:default_organization),
        :code_prefix => 'PTOC',
        :neighbours => [other_work_paper],
        :file_model_attributes => {
          :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH)
        }
      )
    end

    assert_equal 1, @work_paper.errors.count
    assert_equal [error_message_from_model(@work_paper, :code, :taken)],
      @work_paper.errors[:code]
  end
end