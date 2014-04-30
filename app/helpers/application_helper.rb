module ApplicationHelper
  include ParameterSelector

  def copy_attribute_errors(from, to, form_builder)
    form_builder.object.errors[from].each do |message|
      form_builder.object.errors.add(to, message)
    end
  end

  def textilize(text)
    if text.blank?
      ''
    else
      textilized = RedCloth.new(text, [ :hard_breaks ])
      textilized.hard_breaks = true if textilized.respond_to?('hard_breaks=')
      textilized.to_html.html_safe
    end
  end

  def textilize_without_paragraph(text)
    textiled = textilize(text)

    if textiled[0..2] == '<p>' then textiled = textiled[3..-1] end
    if textiled[-4..-1] == '</p>' then textiled = textiled[0..-5] end

    textiled.html_safe
  end

  def calendar_text_field(form, attribute, time = false, value = nil, options = {})
    value ||= form.object.send(attribute)
    default_options = { :class => "#{options.delete(:class)} calendar" }

    default_options[:value] = l(value, :format => time ? :minimal : :default) if value
    default_options['data-time'] = true if time

    form.text_field attribute, default_options.merge(options)
  end

  def super_truncate(text, length = 30)
    unless text.blank?
      omission = content_tag(:abbr, '...', :title => text)
      safe_text = text.gsub '%', '%%'

      truncate(safe_text, :length => length, :omission => '%s') % omission
    end
  end

  def time_in_words_with_abbr(time_in_seconds = 0)
    content_tag(:abbr, time_ago_in_words(time_in_seconds.from_now),
      :title => t('datetime.distance_in_words.x_hours',
        :count => ('%.2f' % (time_in_seconds / 3600)))).html_safe
  end

  def show_info(text, html_options = {})
    content_tag(:div, !text.blank? ?
      content_tag(
        :span, nil, title: text,
        class: "#{html_options[:class]} glyphicon glyphicon-info-sign"
      ) : nil
    ).html_safe
  end

  # Genera un array con pares [[name_field_1, id_field_1],......] para ser
  # utilizados en los selects
  #
  # * _objects_::     Objetos para los que se quiere generar el array
  # * _name_field_::  Campo o método que se va a mostrar en el select
  # * _id_field_::    Campo o método que se va a usar para identificar al objeto
  def options_array_for(objects, name_field, id_field, show_prompt = false)
    raw_options = objects.map { |o| [o.send(name_field), o.send(id_field)] }
    show_prompt ? [[t('helpers.select.prompt'), nil]] + raw_options :
      raw_options
  end

  # Genera un array ordenado con pares [[name_field_1, id_field_1],......] para
  # ser utilizados en los selects
  #
  # Internamente utiliza #options_array_for y #sort_options_array
  #
  # * _objects_::     Objetos para los que se quiere generar el array
  # * _name_field_::  Campo o método que se va a mostrar en el select
  # * _id_field_::    Campo o método que se va a usar para identificar al objeto
  def sorted_options_array_for(objects, name_field, id_field)
    sort_options_array options_array_for(objects, name_field, id_field)
  end

  # Ordena un array que será utilizado en un select por el valor de los campos
  # que serán mostrados
  #
  # * _options_array_:: Arreglo con las opciones que se quieren ordenar
  def sort_options_array(options_array)
    options_array.sort { |o_1, o_2| o_1.first <=> o_2.first }
  end

  # Convierte un arreglo (con cualquier cantidad de arreglos en su interior) en
  # una lista sin ordernar (HTML ul)
  #
  # * _array_:: El arreglo que se quiere convertir a HTML
  # * _options_:: Opciones HTML de la lista principal
  def array_to_ul(array, options = {})
    unless array.blank?
      list = array.map do |e|
        if e.kind_of?(Array) && e.first.kind_of?(String) &&
            e.second.kind_of?(Array)
          content_tag(:li, raw("#{textilize_without_paragraph(e.shift)}\n#{array_to_ul(e)}"))
        else
          if e.kind_of?(Array)
            e.map { |item| content_tag(:li, textilize_without_paragraph(item)) }.join("\n")
          else
            content_tag(:li, textilize_without_paragraph(e))
          end
        end
      end

      content_tag(:ul, raw(list.join("\n")), options)
    end
  end

  # Devuelve el HTML devuelto por un render :partial => 'form', con el texto en
  # el botón submit reemplazado por el indicado. El resultado está "envuelto" en
  # un div con la clase "form_container"
  #
  # * _submit_label_::  Etiqueta que se quiere mostrar en el botón submit del
  #                     formulario
  def render_form(submit_label = t('label.save'), locals_extra = {})
    content_tag :div, render(:partial => 'form',
      :locals => {:submit_text => submit_label}.merge(locals_extra)),
      :class => :form_container
  end

  # Devuelve el HTML de un campo lock_version oculto dentro de un div oculto
  #
  # * _form_:: Formulario que se utilizará para generar el campo oculto
  def hidden_lock_version(form)
    content_tag(:div, form.hidden_field(:lock_version),
      :style => 'display: none;').html_safe
  end

  # Devuelve el nombre de un valor de una lista de opciones para un select.
  #
  # * _options_:: Arreglo con opciones en la forma que las recibe un select
  # * _value_:: Valor del que se quiere el nombre
  #
  #   opciones = [['Valor 1', 1], ['Valor 2', 2]]
  #   name_for_option_value(opciones, 2) #=> 'Valor 2'
  def name_for_option_value(options, value)
    selected = options.rassoc(value)

    return selected ? selected.first : '-'
  end

  # Devuelve el HTML de un botón para invocar un método _destroy_.
  #
  # * <em>*args</em>:: Las mismas opciones que button_to sin la etiqueta
  def button_to_destroy(*args)
    options = {
      :label => t('label.delete')
    }.merge(args.last.kind_of?(Hash) ? args.pop : {})

    html_options = {
      :data => { :confirm => t('message.confirmation_question') },
      :method => :delete,
      :title => t('label.delete'),
      :src => path_to_image('delete.gif')
    }.merge(args.last.kind_of?(Hash) ? args.pop : {})

    image_button_to(options.delete(:label), *(args << html_options))
  end

  def make_filterable_column(title, options = nil, *columns)
    raise 'Must have at least one column' if columns.empty?

    html_classes = []
    content = content_tag(:span, title, :class => :title)
    options ||= {}

    html_classes << (@query.blank? || columns.any?{|c| @columns.include?(c)} ?
      'selected' : 'disabled')
    html_classes << 'visible-lg' if options['visible-lg']

    columns.each do |column|
      content << hidden_field_tag("column_#{column}_for_filter", column)
    end

    content_tag(:th, content.html_safe,
      :class => "filterable #{html_classes.join(' ')}")
  end

  def make_not_available_column(title, options = {})
    html_classes = []

    html_classes << :not_available unless @query.blank? && @order_by.blank?
    html_classes << 'visible-lg' if options['visible-lg']

    content_tag(:th, title,
      :class => (html_classes.join(' ') unless html_classes.blank?))
  end

  # Devuelve el HTML de un vínculo para volver (history.back())
  def link_to_back
    link_to t('label.back'), '#', 'data-event' => 'historyBack'
  end

  # Devuelve el HTML de un vínculo para mostrar el cuadro de búsqueda
  def link_to_search
    search_link = link_to t('label.search'), '#', :onclick => 'Search.show(); return false;',
      :id => :show_search_link, :title => t('message.search_link_title')

    @query.blank? ? search_link : content_tag(:span, search_link,
      :style => 'display: none;')
  end

  # Devuelve el HTML de un vínculo para descargar algo relacionado a un ítem.
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_download(*args)
    options = {:label => t('label.download')}
    html_options = {:class => :image_link}
    options.merge!(args.shift) if args.first.kind_of?(Hash)
    html_options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(content_tag(:span, nil, class: 'glyphicon glyphicon-download-alt',
      title: options.delete(:label)),
      *(args.empty? ? [options, html_options] : args << html_options))
  end

  # Devuelve el HTML de un control para mostrar y ocultar el contenido de un
  # contenedor.
  #
  # * _element_id_:: ID del elemento que se va a mostrar y ocultar
  # * _show_text_:: Texto que se va a mostrar en el title del link para mostrar
  # * _hide_text_:: Texto que se va a mostrar en el title del link para ocultar
  def link_to_show_hide(element_id, show_text, hide_text, displayed = false)
    out = content_tag(:span,
      link_to(
        content_tag(:span, nil, class: 'glyphicon glyphicon-circle-arrow-right'),
        '#', :onclick => "Helper.showOrHideWithArrow('#{element_id}'); return false;"
      ),
      :id => "show_element_#{element_id}_content",
      :style => (displayed ? 'display: none' : nil),
      :class => 'media-object'
    )
    out << content_tag(:span,
      link_to(
        content_tag(:span, nil, class: 'glyphicon glyphicon-circle-arrow-down'),
        '#', :onclick => "Helper.showOrHideWithArrow('#{element_id}'); return false;"
      ),
      :id => "hide_element_#{element_id}_content",
      :style => (displayed ? nil : 'display: none'),
      :class => 'media-object'
    )
  end

  # Devuelve el HTML de un vínculo para mover un ítem.
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_move(*args)
    options = {
      :class => 'image_link move',
      :onclick => 'return false;',
      :title => t('label.move')
    }
    options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(content_tag(:span, nil, class: 'glyphicon glyphicon-move'), '#',
      *(args << options))
  end

  # Devuelve el HTML (con el tag <script>) para establecer el foco en un
  # elemento
  #
  # * _dom_id_::  ID del elemento al que se le quiere establecer el foco
  # * _delay_::   Delay en segundos que se quiere aplicar
  def set_focus_to(dom_id, delay = 0)
    javascript_tag "$('#{dom_id.to_s}').focus.delay(#{delay});"
  end

  # Devuelve HTML con un link para eliminar un componente de un formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  def remove_item_link(fields = nil, class_for_remove = nil, options = {})
    new_record = fields.nil? || fields.object.new_record?
    out = String.new.html_safe
    link_options = {
      :title => t('label.delete'),
      'data-target' => ".#{class_for_remove || fields.object.class.name.underscore}",
      'data-event' => (new_record ? 'removeItem' : 'hideItem')
    }

    out << fields.hidden_field(:_destroy, :class => 'destroy',
      :value => fields.object.marked_for_destruction? ? 1 : 0) unless new_record
    out << link_to(content_tag(:span, nil, class: 'glyphicon glyphicon-remove'),
      '#', link_options.merge(options))
  end

  # Devuelve HTML con un link para eliminar un componente de una lista de un
  #  formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  def remove_list_item_link(fields, remove_class = nil)
    link_to(content_tag(:span, nil, class: 'glyphicon glyphicon-remove'),
      '#', :title => t('label.delete'),
      'data-target' => ".#{remove_class || fields.object.class.name.underscore}",
      'data-event' => 'removeListItem')
  end

  # Devuelve HTML con un link para agregar un elemento
  #
  # * _options_:: Opciones utilizadas por link_to
  def link_to_add(*args)
    options = {
      :class => 'action_link add_link',
      :title => t('label.add'),
      :style => 'margin: 0 5px;'
    }
    options.merge!(args.pop) if args.last.kind_of?(Hash)

    out = String.new.html_safe
    out << link_to(content_tag(:span, nil, class: 'glyphicon glyphicon-plus'), *(args << options))
  end

  def link_to_delete_attachment(form, name, *args)
    options = args.extract_options!
    out = form.hidden_field(
      "delete_#{name}",
      :class => 'destroy',
      :value => form.object.marked_for_destruction? ? 1 : 0
    )
    out << link_to(
      content_tag(:span, nil, class: 'glyphicon glyphicon-remove'), '#', {
        :title => t('label.delete_file'), 'data-event' => 'removeAttachment'
      }.merge(options)
    )

    raw out
  end

  # Devuelve HTML con un link para insertar un componente en un formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  # * _user_options_:: Opciones extra para generar el link (por ejemplo :class)
  def insert_record_link(fields, user_options = {})
    options = {
      :label => t('label.insert_record_item'),
      'data-event' => 'insertRecordItem'
    }.merge(user_options)
    target = ".#{options[:class_to_insert]}" unless options[:class_to_insert].blank?

    link_to(
      content_tag(:div, nil, title: options.delete(:label),
        class: 'glyphicon glyphicon-indent-left'), "#",
      {
        'data-template' => options.delete(:class_to_insert) ||
          fields.object.class.name.underscore,
        'data-target' => target || options.delete('data-target') ||
          ".#{fields.object.class.name.underscore}",
        :class => :image_link
      }.merge(options))
  end

  # Devuelve una etiqueta con el mismo nombre que el del objeto para que sea
  # reemplazado con un ID único por la rutina que reemplaza todo en el navegador
  def dynamic_object_id(prefix, form_builder)
    "#{prefix}_#{form_builder.object_name.to_s.gsub(/[_\]\[]+/, '_')}"
  end

  # Devuelve el HTML necesario para insertar un nuevo ítem en un nested form
  #
  # * _form_builder_::  Formulario "Padre" de la relación anidada
  # * _method_::        Método para invocar la relación anidada (por ejemplo, si
  #                     se tiene una relación Post > has_many :comments, el método
  #                     en ese caso es :comments)
  # * _user_options_::  Optiones del usuario para "personalizar" la generación de
  #                     HTML.
  #    :object => objeto asociado
  #    :partial => partial utilizado para generar el HTML
  #    form_builder_local => nombre de la variable que contiene el objeto form
  #    :locals => Hash con las variables locales que necesita el partial
  #    :child_index => nombre que se pondrá en el lugar donde se debe reemplazar
  #                    por el índice adecuado (por defecto NEW_RECORD)
  #    :is_dynamic => se establece a true si se está generando para luego ser
  #                   insertado múltiples veces.
  def generate_html(form_builder, method, user_options = {})
    options = {
      :object => form_builder.object.class.reflect_on_association(method).klass.new,
      :partial => method.to_s.singularize,
      :form_builder_local => :f,
      :locals => {},
      :child_index => 'NEW_RECORD',
      :is_dynamic => true
    }.merge(user_options)

    form_builder.simple_fields_for(method, options[:object],
      :child_index => options[:child_index]) do |f|
      render(:partial => options[:partial], :locals => {
          options[:form_builder_local] => f,
          :is_dynamic => options[:is_dynamic]
        }.merge(options[:locals]))
    end
  end

  # Genera el mismo HTML que #generate_html con la diferencia que lo escapa para
  # que pueda ser utilizado en javascript.
  def generate_template(form_builder, method, options = {})
    escape_javascript generate_html(form_builder, method, options)
  end

  # Genere un link para ser incluido en el menú. Si no tiene permisos de
  # devuelve el nombre del link en un <span class="disabled">
  #
  # * _controller_names_::    Nombre o nombres de los controladores incluidos en
  #                           el ítem del menú.
  # * _current_controller_::  Controlador que tiene el pedido actual
  # * _extra_condition_::     Condición extra si existe para evaluar si se
  #                           despliega un enlace o sólo el texto
  # * _name_::                Nombre a mostrar en el enlace
  # * <em>*args</em>::        Argumentos extra, ver
  #                           #ActionView::Helpers::UrlHelper.link_to
  def generate_menu_link(module_names, current_module, name, *args)
    selected = false
    has_privileges = false
    options = args.last.kind_of?(Hash) ? (args.pop || {}) : {}

    if module_names.kind_of?(Array)
      selected = module_names.include?(current_module)
      has_privileges = has_privileges_for_any(module_names)
    else
      selected = module_names == current_module
      has_privileges = has_privileges_for(module_names)
    end

    if has_privileges
      if selected
        options[:class] = "#{options[:class]} selected_menu"
      end

      args << options

      link_to(name, *args)
    else
      content_tag(:span, name, :class => :menu_disabled)
    end
  end

  private

  # Devuelve true si el usuario tiene privilegios para utilizar el controlador
  #
  # * _controller_name_::   Nombre del controlador
  def has_privileges_for(module_name) #:doc:
    if @auth_privileges
      privileges = @auth_privileges[module_name.to_sym]

      privileges.kind_of?(Hash) && privileges.values.inject { |r, p| r || p }
    end
  end

  # Devuelve true si el usuario tiene privilegios para utilizar cualquiera de
  # los controladores incluidos en controller_names
  #
  # * _controller_names_::  Arreglo con el nombre de los controladores
  def has_privileges_for_any(module_names) #:doc:
    module_names.any? { |controller| has_privileges_for(controller) }
  end

  # Devuelve un formulario igual que button_to, excepto que el tipo de botón es
  # una imágen
  #
  # * _name_::  Nombre si la imágen no puede ser obtenida
  def image_button_to(name, options = {}, html_options = {})
    html_options = html_options.stringify_keys
    convert_boolean_attributes!(html_options, %w( disabled ))

    method_tag = ''
    if (method = html_options.delete('method')) && %w{patch delete}.include?(method.to_s)
      method_tag = tag('input', :type => 'hidden', :name => '_method', :value => method.to_s)
    end

    form_method = method.to_s == 'get' ? 'get' : 'post'

    remote = html_options.delete('remote')

    request_token_tag = ''
    if form_method == 'post' && protect_against_forgery?
      request_token_tag = tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
    end

    url = options.is_a?(String) ? options : self.url_for(options)
    name ||= url

    html_options = convert_options_to_data_attributes(options, html_options)

    html_options.merge!('type' => 'image', 'title' => name, 'alt' => name)

    ("<form method=\"#{form_method}\" action=\"#{html_escape(url)}\" #{"data-remote=\"true\"" if remote} class=\"button_to\"><div>" +
      method_tag + tag("input", html_options) + request_token_tag + "</div></form>").html_safe
  end
end
