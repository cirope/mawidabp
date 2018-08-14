module ApplicationHelper
  include ParameterSelector

  def page_title
    @title     ||= t "actioncontroller.#{controller_name}"
    organization = "&lt;#{current_organization.name}&gt;" if current_organization

    raw [t('app_name'), organization, @title].compact.join(' ')
  end

  def t_boolean field
    t "navigation.#{field ? '_yes' : '_no'}"
  end

  def copy_attribute_errors(from, to, form_builder)
    form_builder.object.errors[from].each do |message|
      form_builder.object.errors.add(to, message)
    end
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
      omission = content_tag(:abbr, '...', :title => j(text))
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
    content_tag(:div, text.present? ?
      content_tag(
        :span, nil, title: j(text),
        class: "#{html_options[:class]} glyphicon glyphicon-info-sign"
      ) : nil
    ).html_safe
  end

  def simple_icon(title, icon_type)
    content_tag(
      :span, nil, title: j(title),
      class: "glyphicon glyphicon-#{icon_type}"
    )
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
          content_tag(:li, raw("#{markdown_without_paragraph(e.shift)}\n#{array_to_ul(e)}"))
        else
          if e.kind_of?(Array)
            e.map { |item| content_tag(:li, markdown_without_paragraph(item)) }.join("\n")
          else
            content_tag(:li, markdown_without_paragraph(e))
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

  def make_filterable_column(title, options = nil, *columns)
    raise 'Must have at least one column' if columns.empty?

    html_classes = []
    content = content_tag(:span, title, :class => :title)
    options ||= {}

    html_classes << (@query.blank? || columns.any?{|c| @columns.include?(c)} ?
      'selected' : 'disabled')
    html_classes << options[:class] if options[:class]

    columns.each do |column|
      content << hidden_field_tag("column_#{column}_for_filter", column)
    end

    content_tag(:th, content.html_safe,
      :class => "filterable #{html_classes.join(' ')}")
  end

  def make_not_available_column(title, options = {})
    html_classes = []

    html_classes << :not_available unless @query.blank? && @order_by.blank?
    html_classes << options[:class] if options[:class]

    content_tag(:th, title,
      :class => (html_classes.join(' ') unless html_classes.blank?))
  end

  # Devuelve el HTML de un vínculo para mostrar el cuadro de búsqueda
  def link_to_search
    search_link = link_to t('label.search'), '#', :onclick => 'Search.show(); return false;',
      :id => :show_search_link, :class => 'btn btn-xs btn-default',
      :title => t('message.search_link_title')

    @query.blank? ? search_link : content_tag(:span, search_link,
      :style => 'display: none;')
  end

  # Devuelve el HTML de un control para mostrar y ocultar el contenido de un
  # contenedor.
  #
  # * _element_id_:: ID del elemento que se va a mostrar y ocultar
  def link_to_show_hide(element_id)
    out = content_tag(:span,
      link_to(
        content_tag(:span, nil, class: 'glyphicon glyphicon-circle-arrow-right'),
        '#', :onclick => "Helper.showOrHideWithArrow('#{element_id}'); return false;"
      ),
      :id => "show_element_#{element_id}_content",
      :class => 'media-object'
    )
    out << content_tag(:span,
      link_to(
        content_tag(:span, nil, class: 'glyphicon glyphicon-circle-arrow-down'),
        '#', :onclick => "Helper.showOrHideWithArrow('#{element_id}'); return false;"
      ),
      :id => "hide_element_#{element_id}_content",
      :style => 'display: none;',
      :class => 'media-object'
    )
  end

  def link_to_fetch_hide(id, action = :fetch)
    show_link = link_to('#', :data => { action => id }) do
      content_tag(:span, nil, class: 'glyphicon glyphicon-circle-arrow-right')
    end
    hide_link = link_to('#', :data => { :hide => id }) do
      content_tag(:span, nil, class: 'glyphicon glyphicon-circle-arrow-down')
    end

    out  = content_tag(:span, show_link, :class => 'media-object')
    out << content_tag(:span, hide_link, :class => 'media-object hidden')
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
    out << link_to(content_tag(:span, nil, class: 'glyphicon glyphicon-remove-circle'),
      '#', link_options.merge(options))
  end
end
