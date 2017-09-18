require 'test_helper'

# Clase para probar el modelo "WorkPaper"
class WorkPaperTest < ActiveSupport::TestCase
  fixtures :work_papers, :file_models, :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @work_paper = WorkPaper.find work_papers(:image_work_paper).id
    @work_paper.code_prefix = I18n.t("code_prefixes.work_papers_in_control_objectives")

    set_organization
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
      @work_paper = WorkPaper.list.create(
        :owner => control_objective_items(:security_policy_3_1_item),
        :name => 'New name',
        :code => 'PTOC 20',
        :number_of_pages => '10',
        :description => 'New description',
        :organization => organizations(:cirope),
        :code_prefix => 'PTOC',
        :file_model_attributes => {
          :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH)
        }
      )
    end
  end

  test 'create with local path' do
    file_name = File.basename TEST_FILE_FULL_PATH

    FileUtils.cp TEST_FILE_FULL_PATH, "/tmp/#{file_name}"

    assert_difference ['WorkPaper.count', 'FileModel.count'] do
      @work_paper = WorkPaper.list.create(
        :owner => control_objective_items(:security_policy_3_1_item),
        :name => 'New name',
        :code => 'PTOC 21',
        :number_of_pages => '10',
        :description => "New description local://#{file_name}",
        :organization => organizations(:cirope),
        :code_prefix => 'PTOC'
      )
    end

    FileUtils.rm "/tmp/#{file_name}"
  end

  # Prueba de actualización de un papel de trabajo
  test 'update' do
    assert @work_paper.update(:name => 'New name'),
      @work_paper.errors.full_messages.join('; ')
    @work_paper.reload
    # Todos los atributos son de solo lectura
    assert_equal 'New name', @work_paper.name
  end

  # Prueba de eliminación de papeles de trabajo
  test 'delete' do
    assert_difference ['WorkPaper.count', 'FileModel.count'], -1 do
      @work_paper.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @work_paper.organization_id = nil
    @work_paper.name = '    '
    @work_paper.code = '   '

    assert @work_paper.invalid?
    assert_error @work_paper, :organization_id, :blank
    assert_error @work_paper, :name, :blank
    assert_error @work_paper, :code, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @work_paper.organization_id = '_124'
    @work_paper.number_of_pages = '12.3'

    assert @work_paper.invalid?
    assert_error @work_paper, :organization_id, :not_a_number
    assert_error @work_paper, :number_of_pages, :not_an_integer

    @work_paper.reload
    @work_paper.number_of_pages = '100001'

    assert @work_paper.invalid?
    assert_error @work_paper, :number_of_pages, :less_than, count: 100000

    @work_paper.reload
    @work_paper.number_of_pages = '0'

    assert @work_paper.invalid?
    assert_error @work_paper, :number_of_pages, :greater_than, count: 0
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @work_paper.name = 'abcdd' * 52
    @work_paper.code = 'abcdd' * 52

    assert @work_paper.invalid?
    assert_error @work_paper, :name, :too_long, count: 255
    assert_error @work_paper, :code, :too_long, count: 255
  end

  test 'zip created' do
    assert_difference 'WorkPaper.count' do
      @work_paper = WorkPaper.create(
        :owner => control_objective_items(:security_policy_3_1_item),
        :name => 'New name',
        :code => 'PTOC 20',
        :number_of_pages => '10',
        :description => 'New description',
        :organization => organizations(:cirope),
        :code_prefix => 'PTOC',
        :file_model_attributes => {
          :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH)
        }
      )
    end

    assert_equal '.zip', File.extname(@work_paper.reload.file_model.file.path)
  end

  test 'unzip if necesary' do
    assert @work_paper.update(
      :file_model_attributes => {
        :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH)
      }
    )

    assert_equal '.zip', File.extname(@work_paper.reload.file_model.file.path)
    assert_nothing_raised { @work_paper.unzip_if_necesary }
    assert_equal '.html', File.extname(@work_paper.file_model.file.path)
  end

  test 'add a zip attachment' do
    zip_filename = '/tmp/test.zip'
    FileUtils.rm zip_filename if File.exists?(zip_filename)

    Zip::File.open(zip_filename, Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream('test.txt') { |f| f << 'test file' }
    end

    assert @work_paper.update(
      :file_model_attributes => {
        :file => Rack::Test::UploadedFile.new(zip_filename)
      }
    )
    assert_equal '.zip', File.extname(@work_paper.reload.file_model.file.path)
    assert_nothing_raised { @work_paper.unzip_if_necesary }
    assert_equal '.zip', File.extname(@work_paper.file_model.file.path)

    FileUtils.rm zip_filename
  end

  test 'modify a zip attachment repeatedly' do
    zip_filename = '/tmp/test.zip'
    FileUtils.rm zip_filename if File.exists?(zip_filename)

    Zip::File.open(zip_filename, Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream('test.txt') { |f| f << 'test file' }
    end

    assert @work_paper.update(
      :file_model_attributes => {
        :file => Rack::Test::UploadedFile.new(zip_filename)
      }
    )

    assert_equal '.zip', File.extname(@work_paper.reload.file_model.file.path)
    assert_equal 'application/zip', @work_paper.file_model.file.content_type
    assert @work_paper.update(:number_of_pages => 1234)
    assert @work_paper.update(:name => 'Updated test name')
    assert_equal '.zip', File.extname(@work_paper.reload.file_model.file.path)
    assert_equal 'application/zip', @work_paper.file_model.file.content_type
    assert_nothing_raised { @work_paper.unzip_if_necesary }
    assert_equal '.zip', File.extname(@work_paper.reload.file_model.file.path)
    assert_equal 'application/zip', @work_paper.file_model.file.content_type

    count = 0

    assert_difference 'count' do
      Zip::File.foreach(@work_paper.file_model.file.path) do |entry|
        count += 1
      end
    end

    assert Zip::File.open(@work_paper.file_model.file.path).find_entry(
      'test.txt')

    FileUtils.rm zip_filename
  end

  test 'validates duplicated codes' do
    other_work_paper = WorkPaper.find work_papers(:text2_work_paper_unconfirmed_weakness).id

    assert_no_difference 'WorkPaper.count' do
      assert !other_work_paper.owner.update(
        :work_papers_attributes => {
          :new_1 => {
            :name => 'New name',
            :code => other_work_paper.code,
            :number_of_pages => '10',
            :description => 'New description',
            :organization => organizations(:cirope),
            :code_prefix => 'PTO',
            :file_model_attributes => {
              :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH)
            }
          }
        }
      )
    end

    @work_paper = other_work_paper.owner.work_papers.detect(&:new_record?)
    assert_error @work_paper, :code, :taken
  end
end
