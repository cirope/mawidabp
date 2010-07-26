require 'find'

# =Controlador de copias de seguridad
# 
# Lista, crea y restaura las copias de seguridad de la aplicación (#Backup)
class BackupsController < ApplicationController
  before_filter :auth, :check_privileges
  hide_action :delete_old_backups, :do_backup, :do_restore, :load_model,
    :zip_directory, :extract_file, :load_privileges

  # Lista las copias de seguridad realizadas hasta el momento
  #
  # * GET /backups
  # * GET /backups.xml
  def index
    @title = t :'backup.index_title'
    @backups = Backup.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE, :order => 'created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @backups }
    end
  end

  # Muestra el detalle de una copia de seguridad
  #
  # * GET /backups/1
  # * GET /backups/1.xml
  def show
    @title = t :'backup.show_title'
    @backup = Backup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @backup }
    end
  end

  # Permite revisar las opciones para crear una nueva copia de seguridad
  #
  # * GET /backups/new
  # * GET /backups/new.xml
  def new
    @title = t :'backup.new_title'
    @backup = Backup.new(:backup_type => 0, :work_papers_included => true)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @backup }
    end
  end

  # Crea una nueva copia de seguridad
  #
  # * POST /backups
  # * POST /backups.xml
  def create
    @title = t :'backup.new_title'
    @backup = Backup.new(params[:backup].merge(:auth_user_id => @auth_user.id))

    respond_to do |format|
      if !$backup_running && @backup.save
        do_backup(@backup.backup_type, @backup.work_papers_included)
        flash[:notice] = t :'backup.correctly_created'
        format.html { redirect_to(backup_path(@backup, :backup_file => @backup_name)) }
        format.xml  { render :xml => @backup, :status => :created, :location => @backup }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @backup.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Elimina una copia de seguridad
  #
  # * DELETE /backups/1
  # * DELETE /backups/1.xml
  def destroy
    @backup = Backup.find(params[:id])
    @backup.destroy

    respond_to do |format|
      format.html { redirect_to(backups_url) }
      format.xml  { head :ok }
    end
  end

  # Permite seleccionar los datos de la aplicación a partir de una copia
  # anterior
  #
  # * GET /backups/restore_setup
  def restore_setup
    @title = t :'backup.restore_title'
  end

  # Permite restaurar los datos de la aplicación a partir de una copia anterior
  #
  # * POST /backups/restore
  def restore
    @title = t :'backup.restore_title'
    backup_file = params[:backup] && params[:backup][:file] ?
      params[:backup][:file] : nil

    if backup_file && backup_file.content_type == 'application/zip'
      tmp_backup_path = File.join(APP_BACKUP_PATH, 'tmp', File::SEPARATOR)
      backup_path = "#{tmp_backup_path}#{backup_file.original_filename}"

      FileUtils.makedirs tmp_backup_path
      File.open(backup_path, 'w') { |f| f << backup_file.read }

      @restore_ok = do_restore backup_path
    end

    respond_to { |format| format.html { render :action => :restore_setup } }
  end

  private

  # Función que crea la copia de seguridad.
  #
  # Extrae todos los datos de la base de datos, los papeles de trabajo,
  # las imágenes de las organizaciones, etc. y las almacena en un archivo
  # comprimido. Recibe los siguientes parámetros:
  # _type_:: Tipo de copia de seguridad (0 = total, 1 = diferencial)
  # _work_papers_included_:: indica si se deben incluir los papeles de trabajo
  # Estas copias pueden ser recuperadas con #do_restore
  def do_backup(type = 0, work_papers_included = false) #:doc:
    # TODO: mejorar para evitar concurrencia
    $backup_running = true
    conditions = nil
    backup_name = "mawida_backup_#{Time.now.strftime('%Y-%m-%d__%H_%M_%S')}.zip"
    backup_file = "#{APP_BACKUP_PATH}#{backup_name}"

    delete_old_backups

    # Si es diferencial (0 = total, 1 = diferencial)
    if type.respond_to?(:to_i) && type.to_i == 1
      last_full_backup = Backup.first(:conditions => {:backup_type => 0},
        :order => 'created_at DESC')
      conditions = ['created_at > :date_last_full_backup',
        {:date_last_full_backup => last_full_backup.created_at}]
    end

    FileUtils.makedirs APP_BACKUP_PATH
    File.delete backup_file if File.exists? backup_file

    Zip::ZipFile.open(backup_file, Zip::ZipFile::CREATE) do |zipfile|
      # Datos de la base de datos
      zipfile.mkdir 'data'

      APP_MODELS_FOR_BACKUP.each do |model_data|
        name = model_data.kind_of?(String) ? model_data : model_data[0]

        zipfile.get_output_stream(File.join('data', name)) do |entry_file|
          model = name.camelize.constantize
          options = {:lock => true}
          options[:conditions] = conditions if conditions
          options[:include] = model_data[1] if model_data.kind_of?(Array)
          
          model.find_in_batches(options) do |model_items|
            model_items.each do |item|
              attributes = Marshal::load(Marshal::dump(item.attributes))

              if model_data.kind_of?(Array)
                model_data[1].each do |model_relation|
                  relation_name = "#{model_relation.to_s.singularize}_ids"
                  attributes[relation_name] = item.send(relation_name).uniq
                end
              end

              entry_file << YAML.dump(attributes)
            end
          end
        end
      end

      # Copia de los logos de las organizaciones
      zip_directory(zipfile, APP_IMAGES_PATH, 'image_models')
      
      # Datos de los papeles de trabajo
      zip_directory(zipfile, APP_FILES_PATH, 'file_models') if work_papers_included
    end

    @backup_name = backup_name
  ensure
    $backup_running = false
  end

  # Restaura los datos de la base de datos, las imágenes de las organizaciones,
  # los papeles de trabajo, etc. a partir de un archivo conprimido (con
  # #do_backup). Elimina TODOS los datos anteriores y retorna true si no se
  # produjo ningún error durante la restauración.
  # _backup_path_:: Ruta al archivo con la copia de seguridad
  def do_restore(backup_path) #:doc:
    restore_ok = false

    if File.file?(backup_path)
      restore_ok = true
      entries = {}
      
      FileUtils.rm_rf APP_FILES_PATH, :secure => true
      FileUtils.makedirs APP_FILES_PATH
      FileUtils.rm_rf APP_IMAGES_PATH, :secure => true
      FileUtils.makedirs APP_IMAGES_PATH

      Zip::ZipFile.foreach(backup_path) do |entry|
        # Si es un directorio se descarta
        if entry.file?
          if entry.name =~ /^data\/(.+)/
            entries[$1] = entry
          elsif entry.name =~ /^file_models\/(.+)/
            extract_file(entry, $1, APP_FILES_PATH)
          elsif entry.name =~ /^image_models\/(.+)/
            extract_file(entry, $1, APP_IMAGES_PATH)
          end
        end
      end

      # Borrado de todos los datos previos
      APP_MODELS_FOR_BACKUP.each do |model_data|
        entry = entries[model_data.kind_of?(String) ? model_data : model_data[0]]
        model = entry.name.sub(/^data\//, '').camelize.constantize
        model.destroy_all
        # Se usa delete_all y NO destroy_all porque con el plugin has_paper_trail
        # la función destroy no hace realmente un delete
        model.delete_all
      end

      APP_MODELS_FOR_BACKUP.each do |model_data|
        entry = entries[model_data.kind_of?(String) ? model_data : model_data[0]]
        model = entry.name.sub(/^data\//, '').camelize.constantize
        attributes_yml = nil

        entry.get_input_stream do |entry_in|
          entry_in.each_line do |line|
            if line.strip =~ /^---$/
              if attributes_yml
                restore_ok &= load_model model, attributes_yml
              end

              attributes_yml = line
            elsif attributes_yml
              attributes_yml << line
            end
          end

          # El último modelo
          restore_ok &= load_model model, attributes_yml if attributes_yml
        end

        # Para llevar la secuencia del modelo al ID más grande + 1
        # Sólo útil en los motores que usan secuencias (PostgreSQL, Oracle ...)
        if model.connection.respond_to? :reset_pk_sequence!
          model.connection.reset_pk_sequence!(
            model.table_name, model.primary_key)
        elsif model.connection.respond_to? :reset_sequence!
          model.connection.reset_sequence! model.table_name, model.primary_key
        end
      end
    end

    restore_ok
  end

  # Elimina las copias de seguridad almacenadas con más de 2 días de antiguedad
  # (asumiendo que ya fueron descargadas).
  def delete_old_backups #:doc:
    Find.find(APP_BACKUP_PATH) do |path|
      File.delete(path) if File.file?(path) && File.mtime(path) < 2.days.ago
    end
  end

  # Crea el modelo y lo guarda en la base de datos. Los datos se recuperan de
  # los attributos indicados en formato YML, donde:
  # _model_:: Clase del modelo que se quiere cargar
  # _attributes_yml_:: Atributos del modelo en formato YML
  # Devuelve el modelo si fue cargado correctamente
  def load_model(model, attributes_yml) #:doc:
    attributes = HashWithIndifferentAccess.new(YAML.load(attributes_yml))
    
    item = model.new do |i|
      #i.id = attributes['id'] if attributes['id']
      attributes.each do |attr, v|
        i.send("#{attr}=", attr =~ /_ids$/ && v.respond_to?(:uniq) ? v.uniq : v)
      end
    end

    item.restoring_model = true
    puts "Guardando: #{item}"
    item.save()

    if item.errors.size > 0
      puts "\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error in #{model.name}:\n"
      item.errors.each { |*e| p e }
      puts "Atributos: "
      p attributes
      puts "\n\n"
    end

    return item if item.errors.size == 0
  end

  # Comprime todo el contenido de un directorio en un archivo comprimido ZIP
  # donde:
  # _zipfile_:: Archivo zip al que se quiere agregar el directorio
  # _fs_dir_name_:: Ruta al directorio que se quiere comprimir
  # _zip_dir_name_:: Nombre que tendrá el directorio dentro del archivo zip
  def zip_directory(zipfile, fs_dir_name, zip_dir_name) #:doc:
    zipfile.mkdir zip_dir_name

    Find.find(fs_dir_name) do |path|
      # Para "relativizar" el nombre del archivo
      relative_path = path.sub fs_dir_name, ''

      if File.directory?(path) && !relative_path.blank?
        zipfile.mkdir File.join(zip_dir_name, relative_path)
      elsif File.file?(path)
        file_name = File.join(zip_dir_name, relative_path)

        zipfile.get_output_stream(file_name) do |zipout|
          zipout << IO.read(path)
        end
      end
    end
  end

  # Extrae el contenido de una entrada al sistema de archivos, donde:
  # _entry_:: La entrada del archivo comprimido que se quiere descomprimir
  # _name_:: El nombre que se le quiere dar al archivo en el sistema de archivos
  # _directory_:: La ruta al directorio donde se guardará el archivo.
  def extract_file(entry, name, directory) #:doc:
    filename = "#{directory}#{name}"

    FileUtils.makedirs File.dirname(filename)
    entry.extract filename
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :restore => :modify
      })
  end
end