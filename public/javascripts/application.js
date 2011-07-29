// Mantiene el estado de la aplicación
var State = {
  // Hash con el contenido del menú
  menu: {},
  // Contador para generar un ID único
  newIdCounter: 0,
  // Registra la variación en el contenido de los formularios
  unsavedData: false,
  // Texto con la advertencia de que hay datos sin guardar
  unsavedDataWarning: undefined,
  // Variable con los mensajes que se deben mostrar diferidos
  showMessages: [],
  // Variable para indicar si la sesión ha expirado
  sessionExpire: false,
  // Mensaje de error para mostrar cuando falla la validación en línea
  validationFailedMessage: undefined
}

// Utilidades para manipular algunos comportamientos del navegador
var BrowserManipulation = {
  /**
     * Carga la nueva URL con los parámetros indicados (debe ser un Hash)
     */
  changeLocation: function(baseUrl, parameters) {
    var params = Util.merge(jQuery.url(undefined, true).param(), parameters);

    Helper.showLoading();
    var query = [];
    
    for(var param in params) {
      var arg = [encodeURIComponent(param)];
      
      if(params[param]) {arg.push(encodeURIComponent(params[param]));}
      
      query.push(arg.join('='))
    }

    window.location = baseUrl + '?' + query.join('&');
  }
}

// Manejadores de eventos
var EventHandler = {

  /**
     * Agrega un ítem anidado
     */
  addNestedItem: function(e) {
    var template = eval(e.data('template'));

    $(e.data('container')).append(Util.replaceIds(template, /NEW_RECORD/g));
  },

  /**
     * Agrega un subitem dentro de un ítem
     */
  addNestedSubitem: function(e) {
    var parent = '.' + e.data('parent');
    var child = '.' + e.data('child');
    var childContainer = $(child, e.parents(parent));
    var parentObjectId = e.parents(parent).mw('downForIdFromName');
    var template = eval(e.data('template'));

    template = template.replace(/(attributes[_\]\[]+)\d+/g, '$1' +
      parentObjectId);

    childContainer.append(Util.replaceIds(template, /NEW_SUBRECORD/g));
  },

  /**
     * Oculta un elemento (agregado con alguna de las funciones para agregado
     * dinámico)
     */
  hideItem: function(e) {
    var target = e.data('target');
    
    Helper.hideItem(e.parents(target));

    e.prev('input[type=hidden].destroy').val('1');
    
    $('input.sort_number', e.parents(target)).addClass('hidden_sort_number').
      removeClass('sort_number');

    FormUtil.completeSortNumbers();
  },

  /**
     * Simula el comportamiento del botón "Atrás"
     */
  historyBack: function() {
    if(window.history.length > 0) {window.history.back(1);}
  },

  /**
     * Inserta un elemento al final del contenedor
     */
  insertRecordItem: function(e) {
    var template = eval(e.data('template'));

    e.parents(e.data('target')).before(Util.replaceIds(template, /NEW_RECORD/g));
  },

  /**
     * Inserta un subelemento al final del contenedor
     */
  insertRecordSubitem: function(e) {
    var target = e.data('target');
    var parent = '.' + e.data('parent');
    var parentObjectId = e.parents(parent).mw('downForIdFromName');
    var template = eval(e.data('template'));

    template = template.replace(/(attributes[_\]\[]+)\d+/g, '$1' +
      parentObjectId);

    e.parents(target).before(Util.replaceIds(template, /NEW_SUBRECORD/g));
  },

  /**
     * Elimina el elemento del DOM
     */
  removeItem: function(e) {
    Helper.removeItem(e.parents(e.data('target')));
    
    FormUtil.completeSortNumbers();
  },

  /**
     * Elimina el elemento del DOM
     */
  removeListItem: function(e) {
    Helper.removeItem(e.parents('.item'));
  }
}

// Utilidades para formularios
var FormUtil = {
  /**
     * Completa todos los inputs con la clase "sort_number" con números en secuencia
     */
  completeSortNumbers: function() {
    $('input.sort_number').val(function(i) {return i + 1;});
  }
}

// Utilidades varias para asistir con efectos sobre los elementos
var Helper = {
  /**
     * Oculta el elemento indicado
     */
  hideItem: function(element, callback) {
    $(element).stop().slideUp(500, callback);
  },

  /**
     * Oculta el elemento que indica que algo se está cargando
     */
  hideLoading: function(element) {
    $('#loading:visible').hide();

    $(element).attr('disabled', false);
  },

  /**
     * Convierte en "ordenable" (utilizando drag & drop) a un componente
     */
  makeSortable: function(elementId, elements, handles) {
    $(elementId).sortable({
      axis: 'y',
      items: elements,
      handle: handles,
      opacity: 0.6,
      stop: function() { FormUtil.completeSortNumbers(); }
    });
  },

  /**
     * Elimina el elemento indicado
     */
  removeItem: function(element, callback) {
    $(element).stop().slideUp(500, function() {
      $(this).remove();
      
      if(jQuery.isFunction(callback)) {callback();}
    });
  },

  /**
     * Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
     */
  showItem: function(element, callback) {
    var e = $(element);

    if(e.is(':not(:visible)')) {
      e.stop().slideDown(500, function() {
        $(
          '*[autofocus]:not([readonly]):not([disabled]):visible:first', e
        ).focus();

        if(jQuery.isFunction(callback)) {callback();}
      });
    }
  },

  /**
     * Muestra el último ítem que cumple con la regla de CSS
     */
  showLastItem: function(cssRule) {
    Helper.showItem($(cssRule + ':last'));
  },

  /**
     * Muestra una imagen para indicar que una operación está en curso
     */
  showLoading: function(element) {
    $('#loading:not(:visible)').show();

    $(element).attr('disabled', true);
  },

  /**
     * Muestra mensajes en el div "time_left" si existe
     */
  showMessage: function(message, expired) {
    $('span.message', $('#time_left')).html(message);
    $('#time_left:not(:visible)').stop().fadeIn();

    State.sessionExpire = State.sessionExpire || expired;
  },

  showOrHideWithArrow: function(elementId) {
    Helper.toggleItem('#' + elementId, function() {
      var links = [
        '#show_element_' + elementId + '_content',
        '#hide_element_' + elementId + '_content'
      ];
      
      $(links.join(', ')).toggle();
    });
  },

  /**
     * Intercambia los efectos de desplegar y contraer sobre un elemento
     */
  toggleItem: function(element, callback) {
    $(element).slideToggle(500, callback);
  }
}

// Utilidades para generar y modificar HTML
var HTMLUtil = {
  /**
     * Convierte un array en un elemento UL con los items como elementos LI, si
     * el elemento es a su vez un array se convierte recursivamente en un UL
     */
  arrayToUL: function(array, attributes) {
    if($.isArray(array) && array.length > 0) {
      var ul = $('<ul></ul>', attributes);
      
      $.each(array, function() {
        var e = $(this);
        
        if($.isArray(e) && e.length > 1 && typeof e[0] == 'string' &&
          $.isArray(e[1])) {
          var li = $('<li></li>');

          li.append(e.shift());
          li.append(HTMLUtil.arrayToUL(e, {}));

          ul.append(li);
        } else {
          if($.isArray(e)) {
            $.each(e, function() {ul.append($('<li></li>').html($(this)));});
          } else {
            ul.append($('<li></li>').html(e));
          }
        }
      });

      return ul;
    } else {
      return '';
    }
  },

  /**
     * Convierte un arreglo de opciones en un string para insertar dentro de
     * etiquetas
     */
  optionsFromArray: function(optionsArray, selectedValue, includeBlank) {
    var options = $.map(optionsArray, function(e) {
      var optionString = selectedValue && e[0] == selectedValue ?
        '<option selected="selected" value=' + e[1] + '>' + e[0] + '</option>' :
        '<option value=' + e[1] + '>' + e[0] + '</option>'

      return optionString;
    }).join(' ');

    return includeBlank ? '<option value=""></option>' + options : options;
  },

  /**
     * Reemplaza el atributo "src" de un elemento por el mismo con la sufijo
     * _hover
     */
  replaceWithHoverImage: function(e) {
    var src = e.attr('src');

    if(src && !src.match(/_hover/)) {
      e.attr('src', src.replace(/^(.*)\.(.*?)$/, '$1_hover.$2'));
    } else {
      HTMLUtil.replaceWithNormalImage(e);
    }
  },

  /**
     * Reemplaza el atributo "src" de un elemento por el mismo sin el prefijo
     * _hover
     */
  replaceWithNormalImage: function(e) {
    var src = e.attr('src');

    if(src && src.match(/_hover/)) {
      e.attr('src', src.replace(/_hover/, ''));
    }
  },
  
  /**
     * Ejecuta la función HTMLUtil.stylizeInputFile en todos los inputs de tipo file dentro
     * de un contenedor span con clase file_container
     */
  stylizeAllInputFiles: function() {
    $('span.file_container').each(function() {
      HTMLUtil.stylizeInputFile($(this));
      Observer.attachToInputFile($(this));
    });
  },

  /**
     * Aplica un estilo "falso" a los inputs de tipo file
     */
  stylizeInputFile: function(element) {
    if (!element || element.length == 0) return;

    var input = $('input[type=file]', $(element));

    if(input.parents('div.stylized_file').length == 0) {
      element.mousemove(function(event) {
        var left = (event.pageX - $(this).offset().left) - input.width() + 10;
        var container = input.parents('span.file_container');
        var xMin = container.position().left + container.width();
        var xMax = xMin + container.width();

        // Esta pregunta es por un bug en IE7 con overflow: hidden
        if(event.pageX >= xMin && event.pageX <= xMax) {
          input.css({left: left + 'px'});
        }
      });
      
      element.wrap('<div class="stylized_file"></div>');
    }
  },

  /**
     * Actualiza as opciones del select indicado y lo habilita si tiene por lo
     * menos una opción
     */
  updateOptions: function(selectElement, optionsString) {
    var element = $(selectElement);

    element.html(optionsString);
    element.attr('disabled', $('option', element).length == 0);
  }
}

// Manipulación del menú
var Menu = {
  /**
     * Muestra el menú principal
     */
  show: function() {
    $('#app_content').hide();
    
    if($('#main_mobile_menu')) {
      $('#session').show();
      $('#main_mobile_menu').show();
    } else {
      $('#app_content').after(
        $('#main_menu').clone().attr('id', 'main_mobile_menu')
      );
      $('#main_mobile_menu').before($('#session'))
    }
    
    $('#show_menu').hide();
    $('#hide_menu').show();
  },
  
  hide: function() {
    $('#main_mobile_menu').hide();
    $('#session').hide();
    $('#app_content').show();
    $('#hide_menu').hide();
    $('#show_menu').show();
  }
}

// Observadores de eventos
var Observer = {
  /**
     * Adjunta eventos a la sección app_content
     */
  attachToAppContent: function() {
    $('#app_content').live('click', function() {
      if ($(this).hasClass('file_container')) {
        $('input[type=file]', $(this)).click();
      }
    });
  },

  /**
     * Agrega un listener a los eventos de click en el menú principal
     */
  attachToMenu: function() {
    $('#menu_container a').live('click', function(event) {
      var menuName = $(this).attr('href').replace(/.*#/, '')
      var content = State.menu[menuName];
      
      if($(this).hasClass('menu_item_1') && content) {
        $('#menu_level_1').html(content);
        $('#menu_level_2').html('&nbsp;');
        $('.menu_item_1').removeClass('highlight');
        
        event.stopPropagation();
        event.preventDefault();
      } else if($(this).hasClass('menu_item_2') && content) {
        $('#menu_level_2').html(content);
        $('.menu_item_2').removeClass('highlight');
        
        event.stopPropagation();
        event.preventDefault();
      }
      
      $(this).addClass('highlight');
    });
  },
  /**
     * Agrega un listener a los eventos de click en el menú principal en móviles
     */
  attachToMobileMenu: function() {
    $('#main_container a').click(function(event) {
      var e = $(this);
      var menuName = e.attr('href').replace(/.*#/, '');
      var content = State.menu[menuName];

      if(e.is('.menu_item_1, .menu_item_2') && content) {
        $('#main_mobile_menu').data(
          'previous-' + e.parents('ul').data('level'),
          $('#main_mobile_menu').html().escapeHTML()
        );
        
        $('#main_mobile_menu').html(content);

        event.stopPropagation();
        event.preventDefault();
      } else if(e.hasClass('back')) {
        $('#main_mobile_menu').html(
          $('#main_mobile_menu').data(
            'previous-' + e.parents('ul').data('level').previous()
          ).unescapeHTML()
        );
      }
    });
  },
  attachToInputFile: function(span) {
    var input = span.length > 0 ? $('input[type=file]', span) : undefined;

    if(input && input.length > 0) {
      $(input).unbind('change');
            
      $(input).change(function(event) {
        var e = event.target.nodeName == 'input' ? $(event.target) :
          $('input[type="file"]', $(event.target));

        if(e.length > 0 && e.hasClass('file') && !$(e).val().match(/^\s*$/)) {
          var imageTag = $('<img />', {
            src: '/images/new_document.gif',
            width: 22,
            height: 20,
            alt: $(e).val(),
            title: $(e).val()
          });

          if($(e).parents('span.file_container').length > 0) {
            $(e).parents('span.file_container').hide();
            $(e).parents('span.file_container').after(imageTag);
          }
        }
      });
    }
  }
}

// Funciones relacionadas con la búsqueda
var Search = {
  observe: function() {
    $('#column_headers').click(function(event) {
      var e = event.target.nodeName == 'th' ? $(event.target) :
        $('th', $(event.target));

      if(e.length > 0 && e.hasClass('filterable')) {
        var columns = $('input[type="hidden"]', e).map(function() {
          return $(this).val();
        });
        var hiddenFilter = $.map(columns)(function() {
          return 'input[value="' + this + '"]';
        }).join(', ');
        var columnNamesDiv = $('#search_column_names');

        if(e.hasClass('selected')) {
          e.addClass('disabled');
          e.removeClass('selected');

          $(hiddenFilter, columnNamesDiv).remove();
        } else {
          $.each(columns, function() {
            var hiddenColumn = $('<input />', {
              'id': 'search_column_' + this,
              'type': 'hidden',
              'name': 'search[columns][]'
            }).val(this);

            columnNamesDiv.append(hiddenColumn);
          });

          e.addClass('selected');
          e.removeClass('disabled');
        }

        $('#search_query').focus();
      }
    });
  },
  
  show: function() {
    var search = $('#search:not(:visible):not(:animated)');

    if(search.length > 0) {
      var headers = $('th', $('#column_headers'));

      headers.each(function() {
        if($(this).hasClass('filterable')) {
          $(this).addClass('selected');
        } else {
          $(this).addClass('not_available');
        }
      });

      if($('#filter_box').length > 0) {
        $('#filter_box').hide();
        $(search).fadeIn(300, function() {$('#search_query').focus();});
      } else {
        search.fadeIn(300, function() {$('#search_query').focus();});
      }

      $('#show_search_link').hide();

      Search.observe();
    } else {
      $('#search_query').focus();
    }
  }
}

// Utilidades varias
var Util = {
  /**
     * Combina dos hash javascript nativos
     */
  merge: function(hashOne, hashTwo) {
    return jQuery.extend({}, hashOne, hashTwo);
  },

  /**
     * Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
     * único generado con la fecha y un número incremental
     */
  replaceIds: function(s, regex){
    return s.replace(regex, new Date().getTime() + State.newIdCounter++);
  }
}

// Funciones ejecutadas cuando se carga cada página
jQuery(function($) {
  var eventList = $.map(EventHandler, function(v, k ) {return k;});
  
  // Para que los navegadores que no soportan HTML5 funcionen con autofocus
  $('[autofocus]:not([readonly]):not([disabled]):visible:first').focus();
  
  $(document).bind('ajax:after', function(event) {
    Helper.showLoading($(event.target));
  });
  
  $(document).bind('ajax:complete', function(event) {
    Helper.hideLoading($(event.target));
  });

  $(document).keydown(function(event) {
    if (event.which == 32 && event.ctrlKey) {
      Search.show();
      
      event.stopPropagation();
      event.preventDefault();
    }
  });

  $('a[data-event]').live('click', function(event) {
    if (event.stopped) return;
    var eventName = $(this).data('event');

    if($.inArray(eventName, eventList) != -1) {
      EventHandler[eventName]($(this));
      
      event.preventDefault();
      event.stopPropagation();
    }
  });
  
  $('input.calendar:not(.hasDatepicker)').live('focus', function() {
    if($(this).data('time')) {
      $(this).datetimepicker({showOn: 'both'}).focus();
    } else {
      $(this).datepicker({
        showOn: 'both',
        onSelect: function() {$(this).datepicker('hide');}
      }).focus();
    }
  });

  // Cuando se remueve o se oculta un papel de trabajo reutilizar el código
  $('.work_paper').live("item:removed", function() {
    var workPaperCode = $('input[name$="[code]"]', $(this)).val();

    if(workPaperCode == lastWorkPaperCode) {
      lastWorkPaperCode = lastWorkPaperCode.previous(2);
    }
  });
  
  $('.popup').dialog({
    autoOpen: false,
    draggable: false,
    resizable: false,
    close: function() {
      $(this).parents('.ui-dialog').show().fadeOut(500);
    },
    open: function(){
      $(this).parents('.ui-dialog').hide().fadeIn(500);
    }
  });
  
  $('span.popup_link').live('click', function(event) {
    $($(this).data('helpDialog')).dialog('open').dialog(
      'option', 'position', [event.pageX, event.pageY]
    );
    
    return false;
  });

  if($('#app_content').length > 0) {
    Observer.attachToAppContent();
    
    $('img').mouseover(function() {
      if($(this).hasClass('change_on_hover')) {
        HTMLUtil.replaceWithHoverImage($(this));
      }
    });
    
    $('img').mouseout(function() {
      if($(this).hasClass('change_on_hover')) {
        HTMLUtil.replaceWithNormalImage($(this));
      }
    });
  }

  if($('#menu_container').length > 0 && !/Apple.*Mobile/.test(navigator.userAgent)) {
    Observer.attachToMenu();
  } else if($('#mobile_menu').length > 0) {
    Observer.attachToMobileMenu();
  }

  // Mensajes diferidos
  if($.isArray(State.showMessages)) {
    $.each(State.showMessages, function() {
      var message = this.message;
      var expired = this.expired;
      
      this.timer_id = window.setTimeout(
        "Helper.showMessage('" + message + "', " + expired + ")",
        this.time * 1000
      );
    });
  }
  
  $(document).bind({
    // Reinicia los timers con los mensajes diferidos
    ajaxStart: function() {
      $.each(State.showMessages, function() {
        if(!State.sessionExpire) {
          window.clearTimeout(this.timer_id);
          $('#time_left').hide();

          var message = this.message;
          var expired = this.expired;

          this.timer_id = window.setTimeout(
            "Helper.showMessage('" + message + "', " + expired + ")",
            this.time * 1000
          );
        }
      });
    }
  });
  
  $('#loading').bind({
    ajaxStart: function() { $(this).show(); },
    ajaxStop: function() { $(this).hide(); }
  });
  
  AutoComplete.observeAll();
});