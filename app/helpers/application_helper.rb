# =Helper de la aplicación
#
# Helper del que heredan los demás helpers de la aplicación.
#
# Todas las funciones definidas aquí están disponibles para *TODOS* los demás
# helpers y quedan también disponibles en las vistas
module ApplicationHelper
  include ParameterSelector

  def super_truncate(text, length = 30)
    omission = content_tag(:acronym, '...', :title => h(text))
    text_length = text.mb_chars.length

    truncate(h(text_length > length ?
          text.dup.concat('.' * omission.mb_chars.length) : text),
      :length => text_length > length ?
        (length + omission.mb_chars.length) : length,
      :omission => omission
    )
  end

  def time_in_words_with_acronym(time_in_seconds = 0)
    content_tag :acronym, time_ago_in_words(time_in_seconds.from_now),
      :title => t(:'datetime.distance_in_words.x_hours',
        :count => ('%.2f' % (time_in_seconds / 3600)))
  end

  def show_inline_help_for(name, link_name = nil)
    render :partial => 'inline_helps/show_inline', :locals => {:name => name,
      :link_name => (link_name || name)}
  end

  def show_info(text, html_options = {})
    content_tag(:span, !text.blank? ? content_tag(:acronym, 'i', :title => text,
      :class => "info #{html_options[:class]}") : '&nbsp;', :class => :info_box)
  end

  # Genera un array con pares [[name_field_1, id_field_1],......] para ser
  # utilizados en los selects
  #
  # * _objects_::     Objetos para los que se quiere generar el array
  # * _name_field_::  Campo o método que se va a mostrar en el select
  # * _id_field_::    Campo o método que se va a usar para identificar al objeto
  def options_array_for(objects, name_field, id_field, show_prompt = false)
    raw_options = objects.map { |o| [o.send(name_field), o.send(id_field)] }
    show_prompt ? [[t(:'support.select.prompt'), nil]] + raw_options :
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
          content_tag(:li, "#{textilize(e.shift)}\n#{array_to_ul(e)}")
        else
          if e.kind_of?(Array)
            e.map {|item| content_tag(:li, textilize(item)) }.join("\n")
          else
            content_tag(:li, textilize(e))
          end
        end
      end

      content_tag(:ul, list.join("\n"), options)
    end
  end

  # Devuelve el HTML devuelto por un render :partial => 'form', con el texto en
  # el botón submit reemplazado por el indicado. El resultado está "envuelto" en
  # un div con la clase "form_container"
  #
  # * _submit_label_::  Etiqueta que se quiere mostrar en el botón submit del
  #                     formulario
  def render_form(submit_label = t(:'label.save'))
    content_tag :div, render(:partial => 'form',
      :locals => {:submit_text => submit_label}), :class => :form_container
  end

  # Devuelve el HTML de un campo lock_version oculto dentro de un div oculto
  #
  # * _form_:: Formulario que se utilizará para generar el campo oculto
  def hidden_lock_version(form)
    content_tag :div, form.hidden_field(:lock_version),
      :style => 'display: none;'
  end

  # Devuelve el HTML con los links para navegar una lista paginada
  #
  # * _objects_:: Objetos con los que se genera la lista paginada
  def pagination_links(objects)
    previous_label = "&laquo; #{t :'label.previous'}"
    next_label = "#{t :'label.next'} &raquo;"

    result = will_paginate objects, :previous_label => previous_label,
      :next_label => next_label, :inner_window => 1, :outer_window => 1

    result ||= content_tag(:div, content_tag(:span, previous_label,
        :class => 'disabled prev_page') +
        content_tag(:span, 1, :class => :current) + content_tag(:span,
        next_label, :class => 'disabled next_page'),
      :class => :pagination)

    result
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
      :label => t(:'label.delete')
    }.merge(args.last.kind_of?(Hash) ? args.pop : {})

    html_options = {
      :confirm => t(:'message.confirmation_question'),
      :method => :delete,
      :title => t(:'label.delete'),
      :src => path_to_image('delete.gif')
    }.merge(args.last.kind_of?(Hash) ? args.pop : {})
    
    image_button_to(options.delete(:label), *(args << html_options))
  end

  def make_filterable_column(title, *columns)
    raise 'Must have at least one column' if columns.empty?

    html_class = @query.blank? || columns.any? { |c| @columns.include?(c) } ?
      'selected' : 'disabled'
    content = content_tag(:span, title, :class => :title)

    columns.each do |column|
      content << hidden_field_tag("column_#{column}_for_filter", column)
    end

    content_tag(:th, content, :class => "filterable #{html_class}")
  end

  def make_not_available_column(title)
    content_tag :th, title, :class => (@query.blank? ? nil : :not_available)
  end

  # Devuelve el HTML de un vínculo para volver (history.back())
  def link_to_back
    link_to t(:'label.back'), '#', :class => :history_back
  end

  # Devuelve el HTML de un vínculo para mostrar el cuadro de búsqueda
  def link_to_search
    search_link = link_to_function t(:'label.search'), 'Search.show()',
      :id => :show_search_link, :title => t(:'message.search_link_title')

    @query.blank? ? search_link : content_tag(:div, search_link,
      :style => 'display: none;')
  end

  # Devuelve el HTML de un vínculo para editar un ítem.
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_edit(*args)
    html_options = {:class => :image_link}
    options = {:label => t(:'label.edit')}
    options.merge!(args.pop) if args.last.kind_of?(Hash)
    html_options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(image_tag('edit.gif', :size => '19x18', :alt => options[:label],
        :title => options.delete(:label)), *(args << html_options))
  end

  # Devuelve el HTML de un vínculo para mostrar un ítem.
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_show(*args)
    html_options = {:class => :image_link}
    options = {:label => t(:'label.show')}
    options.merge!(args.pop) if args.last.kind_of?(Hash)
    html_options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(image_tag('view.gif', :size => '24x20', :alt => options[:label],
        :title => options.delete(:label)), *(args << html_options))
  end

  # Devuelve el HTML de un vínculo para descargar algo relacionado a un ítem.
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_download(*args)
    options = {:label => t(:'label.download')}
    html_options = {:class => :image_link}
    options.merge!(args.shift) if args.first.kind_of?(Hash)
    html_options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(image_tag('download.gif', :size => '23x24',
        :alt => options[:label], :title => options.delete(:label)),
      *(args.empty? ? [options, html_options] : args << html_options))
  end

  # Devuelve el HTML de un control para mostrar y ocultar el contenido de un
  # contenedor.
  #
  # * _element_id_:: ID del elemento que se va a mostrar y ocultar
  # * _show_text_:: Texto que se va a mostrar en el title del link para mostrar
  # * _hide_text_:: Texto que se va a mostrar en el title del link para ocultar
  def link_to_show_hide(element_id, show_text, hide_text, displayed = false)
    out = content_tag(:div,
      link_to_function(
        image_tag(
          'grayarrow.gif', :size => '11x11', :alt => '>', :title => show_text
        ),
        "Helper.showOrHideWithArrow('#{element_id}')", :class => :image_link
      ),
      :id => "show_element_#{element_id}_content", :class => :show_hide,
      :style => (displayed ? 'display: none' : nil)
    )
    out << content_tag(:div,
      link_to_function(
        image_tag(
          'grayarrowdown.gif', :size => '11x11', :alt => '>',
          :title => hide_text
        ),
        "Helper.showOrHideWithArrow('#{element_id}')", :class => :image_link
      ),
      :id => "hide_element_#{element_id}_content", :class => :show_hide,
      :style => (displayed ? nil : 'display: none'))
  end

  # Devuelve el HTML de un vínculo para mover un ítem.
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_move(*args)
    options = {
      :class => 'image_link move',
      :onclick => 'return false;',
      :title => t(:'label.move')
    }
    options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(image_tag('move.png', :size => '6x14', :alt => '[M]'), '#',
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

  # Devuelve el HTML (con el tag <script>) para establecer el foco en el primer
  # elemento del primer formulario declarado
  def set_focus_to_first_element
    javascript_tag 'FormManipulation.focusFirst();'
  end

  # Devuelve HTML con un link para eliminar un componente de un formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  def remove_item_link(fields = nil, class_for_remove = nil)
    new_record = fields.nil? || fields.object.new_record?
    out = String.new
    out << fields.hidden_field(:_destroy,
      :value => fields.object.marked_for_destruction? ? 1 : 0) unless new_record
    out << link_to('X',
      "##{class_for_remove || fields.object.class.name.underscore}",
      :class => "remove_link #{(new_record ? :remove_item : :hide_item)}",
      :title => t(:'label.delete'))
  end

  # Devuelve HTML con un link para eliminar un componente de una lista de un
  #  formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  def remove_list_item_link(fields)
    link_to('X', "##{fields.object.class.name.underscore}",
      :class => 'remove_link remove_list_item', :title => t(:'label.delete'))
  end

  # Devuelve HTML con un link para agregar un elemento
  #
  # * _options_:: Opciones utilizadas por link_to
  def link_to_add(*args)
    options = {
      :class => 'action_link add_link',
      :title => t(:'label.add')
    }
    options.merge!(args.pop) if args.last.kind_of?(Hash)

    out = String.new
    out << link_to('+', *(args << options))
  end

  # Devuelve el HTML de un vínculo para clonar un ítem.
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_clone(*args)
    html_options = {:class => :image_link}
    options = {:label => t(:'label.copy')}
    options.merge!(args.pop) if args.last.kind_of?(Hash)
    html_options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(image_tag('copy_document.gif', :size => '20x21',
        :alt => options[:label], :title => options.delete(:label)),
      *(args << html_options))
  end

  # Devuelve HTML con un link para insertar un componente en un formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  # * _user_options_:: Opciones extra para generar el link (por ejemplo :class)
  def insert_record_link(fields, user_options = {})
    options = {
      :label => t(:'label.insert_record_item'),
      :class => :insert_record_item
    }.merge(user_options)
    
    link_to(
      image_tag('insert.gif', :size => '19x13', :alt => options[:label],
        :title => options.delete(:label), :class => options[:class]),
      "##{options.delete(:class_to_insert) || fields.object.class.name.underscore}",
      {
        :class => "insert_record_item image_link #{options.delete(:class)}",
        :rel => options.delete(:rel)
      })
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

    form_builder.fields_for(method, options[:object],
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
    if (method = html_options.delete('method')) &&
        %w{put delete}.include?(method.to_s)
      method_tag = tag('input', :type => 'hidden', :name => '_method',
        :value => method.to_s)
    end

    form_method = method.to_s == 'get' ? 'get' : 'post'

    request_token_tag = ''
    if form_method == 'post' && protect_against_forgery?
      request_token_tag = tag(:input, :type => "hidden",
        :name => request_forgery_protection_token.to_s,
        :value => form_authenticity_token)
    end

    if confirm = html_options.delete("confirm")
      html_options["onclick"] = "return #{confirm_javascript_function(confirm)};"
    end

    url = options.is_a?(String) ? options : self.url_for(options)
    name ||= url

    html_options.merge!('type' => 'image', 'title' => name, 'alt' => name)

    "<form method=\"#{form_method}\" action=\"#{escape_once url}\" class=\"button-to\"><div>" +
      method_tag + tag(:input, html_options) + request_token_tag + "</div></form>"
  end
end