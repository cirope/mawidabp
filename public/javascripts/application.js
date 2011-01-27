// Mantiene el estado de la aplicación
var State = {
    // Hash con el contenido del menú
    menu: new Hash(),
    // Contador para generar un ID único
    newIdCounter: 0,
    // Dimensiones del área visible del navegador
    dimensions: $H({width: 0, height: 0}),
    // Registra la variación en el contenido de los formularios
    unsavedData: false,
    // Texto con la advertencia de que hay datos sin guardar
    unsavedDataWarning: undefined,
    // Variable con los mensajes que se deben mostrar diferidos
    showMessages: new Array(),
    // Variable para indicar si la sesión ha expirado
    sessionExpire: false
}

// Utilidades para asistir al autocompletado
var AutoComplete = {
    /**
     * Escribe en el primer campo oculto del contenedor de la búsqueda (div.search)
     * el ID del objeto seleccionado
     */
    itemSelected: function(text, li) {
        var objectId = $(li).id.strip().match(/id_(\d+)$/)[1];

        $(text).setValue($F(text).strip());
        $(text).up('div.search').select('.autocomplete_id_item').invoke(
            'setValue', objectId);
    }
}

// Utilidades para manipular algunos comportamientos del navegador
var BrowserManipulation = {
    /**
     * Carga la nueva URL con los parámetros indicados (debe ser un Hash)
     */
    changeLocation: function(baseUrl, parameters) {
        var currentUrl = window.location.toString();
        var oldParameters = currentUrl.include('?') ?
            currentUrl.toQueryParams() : {};

        Helper.showLoading();

        window.location = baseUrl + '?' +
            $H(oldParameters).merge(parameters).toQueryString();
    }
}

// Manejadores de eventos
var EventHandler = {
    eventList: $A([
        'addNestedItem',
        'addNestedSubitem',
        'hideItem',
        'historyBack',
        'insertRecordItem',
        'insertRecordSubitem',
        'removeItem',
        'removeListItem'
    ]),

    /**
     * Agrega un ítem anidado
     */
    addNestedItem: function(e) {
        var template = eval(e.readAttribute('data-template'));

        $(e.readAttribute('data-container')).insert({
            bottom: Util.replaceIds(template, /NEW_RECORD/)
        });
    },

    /**
     * Agrega un subitem dentro de un ítem
     */
    addNestedSubitem: function(e) {
        var parent = '.' + e.readAttribute('data-parent');
        var child = '.' + e.readAttribute('data-child');
        var childContainer = e.up(parent).down(child);
        var parentObjectId = e.up(parent).downForIdFromName();
        var template = eval(e.readAttribute('data-template'));

        template = template.replace(/(attributes[_\]\[]+)\d+/g, '$1' +
            parentObjectId);

        childContainer.insert({bottom: Util.replaceIds(template, /NEW_SUBRECORD/)});
    },

    /**
     * Oculta un elemento (agregado con alguna de las funciones para agregado
     * dinámico)
     */
    hideItem: function(e) {
        var target = e.readAttribute('data-target');

        Helper.hideItem(e.up(target));

        var hiddenInput = e.previous('input[type=hidden].destroy') ||
            e.up('a').previous('input[type=hidden].destroy');

        if(hiddenInput) {hiddenInput.setValue('1');}

        if(e.up(target).down('input.sort_number')) {
            e.up(target).down('input.sort_number').
                addClassName('hidden_sort_number').
                removeClassName('sort_number');
        }

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
        var target = e.readAttribute('data-target');
        var template = eval(e.readAttribute('data-template'));

        $(e.up(target)).insert({before: Util.replaceIds(template, /NEW_RECORD/)});
    },

    /**
     * Inserta un subelemento al final del contenedor
     */
    insertRecordSubitem: function(e) {
        var target = e.readAttribute('data-target');
        var parent = '.' + e.readAttribute('data-parent');
        var parentObjectId = e.up(parent).downForIdFromName();
        var template = eval(e.readAttribute('data-template'));

        template = template.replace(/(attributes[_\]\[]+)\d+/g, '$1' +
            parentObjectId);

        $(e.up(target)).insert({
            before: Util.replaceIds(template, /NEW_SUBRECORD/)
        });
    },

    /**
     * Elimina el elemento del DOM
     */
    removeItem: function(e) {
        var target = e.readAttribute('data-target');

        Helper.removeItem(e.up(target));
        FormUtil.completeSortNumbers();
    },

    /**
     * Elimina el elemento del DOM
     */
    removeListItem: function(e) {
        Helper.removeItem(e.up('.item'));
    }
}

// Utilidades para formularios
var FormUtil = {
    /**
     * Completa todos los inputs con la clase "sort_number" con números en secuencia
     */
    completeSortNumbers: function() {
        var number = 1;

        $$('input.sort_number').each(function(e) {e.setValue(number++);});
    }
}

// Utilidades para manipular formularios
var FormManipulation = {
    /**
     * Establece el foco en el primer elemento, siempre que tenga sentido (un input,
     * un select, un textarea) y no esté deshabilitado o con el atributo readonly
     */
    focusFirst: function(container) {
        var c = $(container) || $$('form').first();

        if(c) {
            var elements = c.select('.focused', 'input[type=text]', 'select',
                'textarea', 'input[type=password]');

            while(Object.isArray(elements) && elements.size() > 0) {
                var element = elements.shift();
                var readonly = element.readAttribute('readonly') ||
                    element.readAttribute('disabled');

                if(!readonly) {
                    element.focus();
                    elements = undefined;
                }
            }
        }
    }
}

// Utilidades varias para asistir con efectos sobre los elementos
var Helper = {
    /**
     * Oculta el elemento indicado
     */
    hideItem: function(element, options) {
        Effect.SlideUp(element, Util.merge({
            duration: 0.5,
            afterFinish: function() { element.fire("item:hidden"); }
        }, options));
    },

    /**
     * Oculta el elemento que indica que algo se está cargando
     */
    hideLoading: function(element) {
        $('loading').hide();

        if($(element)) {$(element).enable();}
    },

    /**
     * Convierte en "ordenable" (utilizando drag & drop) a un componente
     */
    makeSortable: function(elementId, elements, handles) {
        Sortable.create(elementId, {
            scroll: window,
            elements: $$(elements),
            handles: $$(handles),
            onChange: function() {FormUtil.completeSortNumbers();}
        });
    },

    /**
     * Elimina el elemento indicado
     */
    removeItem: function(element, options) {
        Effect.SlideUp(element, Util.merge({
            duration: 0.5,
            afterFinish: function() {
                $(element).remove();
                FormUtil.completeSortNumbers();
            }
        }, options));

        element.fire("item:removed");
    },

    /**
     * Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
     */
    showItem: function(element, options) {
        var e = $(element);

        if(e != null && !e.visible()) {
            Effect.SlideDown(e, Util.merge({
                duration: 0.5,
                afterFinish: function() {
                    FormManipulation.focusFirst(e);
                    e.fire("item:displayed");
                }
            }, options));
        }
    },

    /**
     * Muestra el último ítem que cumple con la regla de CSS
     */
    showLastItem: function(cssRule) {
        Helper.showItem($$(cssRule).last());
    },

    /**
     * Muestra una imagen para indicar que una operación está en curso
     */
    showLoading: function(element) {
        $('loading').show();

        if($(element)) {$(element).disable();}
    },

    /**
     * Muestra mensajes en el div "time_left" si existe
     */
    showMessage: function(message, expired) {
        if($('time_left')) {
            $('time_left').down('span.message').update(message);

            if(!$('time_left').visible()) {Element.appear('time_left');}
        }

        State.sessionExpire = State.sessionExpire || expired
    },

    showOrHideWithArrow: function(elementId) {
        Helper.toggleItem(elementId, {
            afterFinish: function() {
                var links = $A(['show_element_#{element_id}_content',
                    'hide_element_#{element_id}_content']);

                links.each(function(link) {
                    Element.toggle(link.interpolate({element_id: elementId}));
                });
            }
        });
    },

    /**
     * Intercambia los efectos de desplegar y contraer sobre un elemento
     */
    toggleItem: function(element, options) {
        Effect.toggle(element, 'slide', Util.merge({duration: 0.5}, options));
    },

    /**
     * Función invocada cuando se redimensiona el área visible del navegador
     */
    updateDimensions: function() {
        State.dimensions = $H(document.viewport.getDimensions());
    }
}

// Utilidades para generar y modificar HTML
var HTMLUtil = {
    /**
     * Convierte un array en un elemento UL con los items como elementos LI, si
     * el elemento es a su vez un array se convierte recursivamente en un UL
     */
    arrayToUL: function(array, attributes) {
        if(Object.isArray(array) && array.length > 0) {
            var ul = new Element('ul', attributes);

            $A(array).each(function(e) {
                if(Object.isArray(e) && e.length > 1 && Object.isString(e[0]) &&
                    Object.isArray(e[1])) {
                    var li = new Element('li');

                    li.insert(e.shift());
                    li.insert(HTMLUtil.arrayToUL(e, {}));

                    ul.insert(li);
                } else {
                    if(Object.isArray(e)) {
                        $A(e).each(function(item) {
                            ul.insert(new Element('li').update(item));
                        });
                    } else {
                        ul.insert(new Element('li').update(e));
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
        var options = $A(optionsArray).collect(function(e) {
            var vals = {text: e[0], value: e[1]};
            var option_string = selectedValue && e[0] == selectedValue ?
                '<option selected="selected" value=#{value}>#{text}</option>' :
                '<option value=#{value}>#{text}</option>'

            return option_string.interpolate(vals);
        }).join();

        return includeBlank ? '<option value=""></option>' + options : options;
    },

    /**
     * Reemplaza el atributo "src" de un elemento por el mismo con la sufijo
     * _hover
     */
    replaceWithHoverImage: function(e) {
        var src = e.readAttribute('src');

        if(src && !src.match(/_hover/)) {
            e.writeAttribute('src', src.sub(/^(.*)\.(.*?)$/,
                '#{1}_hover.#{2}'));
        } else {
            HTMLUtil.replaceWithNormalImage(e);
        }
    },

    /**
     * Reemplaza el atributo "src" de un elemento por el mismo sin el prefijo
     * _hover
     */
    replaceWithNormalImage: function(e) {
        var src = e.readAttribute('src');

        if(src && src.match(/_hover/)) {
            e.writeAttribute('src', e.src.sub(/_hover/, ''));
        }
    },

    /**
     * Función para ordenar un arreglo de opciones para usar en un select
     */
    sortOptionsArray: function(optionsArray) {
        return $A(optionsArray).sortBy(function(s) {return s[0];});
    },

    /**
     * Ejecuta la función HTMLUtil.stylizeInputFile en todos los inputs de tipo file dentro
     * de un contenedor span con clase file_container
     */
    stylizeAllInputFiles: function() {
        $$('span.file_container').each(function(e) {
            HTMLUtil.stylizeInputFile(e);
            Observer.attachToInputFile(e);
        });
    },

    /**
     * Aplica un estilo "falso" a los inputs de tipo file
     */
    stylizeInputFile: function(element) {
        if (!element) return;

        var input = element.down('input[type=file]');

        if(input && !input.up('div.stylized_file')) {
            element.observe('mousemove', function(event) {
                var left = (event.pointerX() -
                    this.positionedOffset()['left']) - input.getWidth();
                var containerLayout =
                    input.up('span.file_container').getLayout();
                var xMin = containerLayout.get('left') +
                    containerLayout.get('width');
                var xMax = xMin + containerLayout.get('width');

                // Esta pregunta es por un bug en IE7 con overflow: hidden
                if(event.pointerX() >= xMin && event.pointerX() <= xMax) {
                    input.setStyle({left: left + 'px'});
                }
            }).wrap('div', {'class' : 'stylized_file'});
        }
    },

    /**
     * Actualiza as opciones del select indicado y lo habilita si tiene por lo
     * menos una opción
     */
    updateOptions: function(selectElement, optionsString) {
        var element = $(selectElement);

        element.update(optionsString);

        if (element.options.length > 0) {
            element.enable()
        } else {
            element.disable()
        }
    }
}

// Manipulación del menú
var Menu = {
    /**
     * Muestra el menú principal
     */
    show: function() {
        $('app_content').update($('main_menu').clone(true).writeAttribute('id',
            'main_mobile_menu'));
    }
}

// Observadores de eventos
var Observer = {
    /**
     * Adjunta eventos a la sección app_content
     */
    attachToAppContent: function() {
        $('app_content').on('click', function(event, element) {
            if (element.hasClassName('file_container')) {
                element.down('input[type=file]').click();
            }
        });
    },

    /**
     * Agrega un listener a los eventos de click en el menú principal
     */
    attachToMenu: function() {
        Event.observe('menu_container', 'click', function(event) {
            var e = Event.findElement(event, 'a');
            var menuName = e ? e.readAttribute('href').replace(/.*#/, '') : '';
            var content = State.menu.get(menuName);

            if(e && e.hasClassName('menu_item_1') && content) {
                $('menu_level_1').update(content);
                $('menu_level_2').update('&nbsp;');
                $$('.menu_item_1').invoke('restoreStyleProperty', 'background');

                Event.stop(event);
            } else if (e && e.hasClassName('menu_item_2') && content) {
                $('menu_level_2').update(content);
                $$('.menu_item_2').invoke('restoreStyleProperty', 'background');

                Event.stop(event);
            } else if (e) {
                $$('.menu_item_1').invoke('restoreStyleProperty', 'background');
                $$('.menu_item_2').invoke('restoreStyleProperty', 'background');
                Helper.showLoading();
            }

            if(e) {
                e.storeStyleProperty('background');
                e.setStyle({'background': '#b1aea6'});
            }
        });
    },
    /**
     * Agrega un listener a los eventos de click en el menú principal en móviles
     */
    attachToMobileMenu: function() {
        Event.observe('app_content', 'click', function(event) {
            var e = Event.findElement(event, 'a');
            var menuName = e ? e.readAttribute('href').replace(/.*#/, '') : '';
            var content = State.menu.get(menuName);

            if(e && (e.hasClassName('menu_item_1') ||
                e.hasClassName('menu_item_2')) && content) {
                $('app_content').update(content);

                Event.stop(event);
            }
        });
    },
    attachToInputFile: function(span) {
        var input = span ? span.down('input[type=file]') : undefined;

        if(input) {
            Event.stopObserving(input, 'change');
            
            Event.observe(input, 'change', function(event) {
                var e = Event.findElement(event, 'input[type="file"]');

                if(e && e.hasClassName('file') && !$F(e).blank()) {
                    var imageTag = new Element('img', {
                        src: '/images/new_document.gif',
                        width: 22,
                        height: 20,
                        alt: $F(e),
                        title: $F(e)
                    });

                    if($(e).up('span.file_container')) {
                        $(e).up('span.file_container').hide();
                        $(e).up('span.file_container').insert(
                            {after: imageTag});
                    }
                }
            });
        }
    }
}

// Funciones para mostrar las ayudas en línea (se completa dinámico desde el
// partial)
var PopupListener = {}

// Funciones relacionadas con la búsqueda
var Search = {
    observe: function() {
        Event.observe('column_headers', 'click', function(event) {
            var e = Event.findElement(event, 'th');

            if(e && e.hasClassName('filterable')) {
                var columns =
                    $A(e.select('input[type="hidden"]').invoke('getValue'));
                var hiddenFilter = columns.collect(function(c) {
                    return 'input[value="' + c + '"]';
                }).join(', ');
                var columnNamesDiv = $('search_column_names');

                if(e.hasClassName('selected')) {
                    e.addClassName('disabled');
                    e.removeClassName('selected');

                    columnNamesDiv.select(hiddenFilter).invoke('remove');
                } else {
                    columns.each(function(column) {
                        var hiddenColumn = new Element('input');
                        
                        hiddenColumn.setValue(column);
                        hiddenColumn.setAttribute('type', 'hidden');
                        hiddenColumn.setAttribute('name', 'search[columns][]');
                        hiddenColumn.setAttribute('id', 'search_column_' +
                            column);

                        columnNamesDiv.insert({bottom: hiddenColumn});
                    });

                    e.addClassName('selected');
                    e.removeClassName('disabled');
                }

                $('search_query').focus();
            }
        });
    },
    show: function(options) {
        var search = $('search');

        if(search && !search.visible()) {
            var headers = Element.select($('column_headers'), 'th');
            var default_options = {
                duration: 0.5,
                queue: {position: 'end', scope: 'search', limit: 1},
                afterFinish: function() {
                    $('search_query').focus();
                }
            }

            headers.each(function(th) {
                if(th.hasClassName('filterable')) {
                    th.addClassName('selected');
                } else {
                    th.addClassName('not_available');
                }
            });

            if($('filter_box')) {
                Element.hide('filter_box')
                Element.show(search);
                $('search_query').focus();
            } else {
                Effect.Appear(search, Util.merge(default_options, options));
            }

            Element.hide('show_search_link');

            Search.observe();
        } else if(search) {
            $('search_query').focus();
        }
    }
}

// Utilidades varias
var Util = {
    /**
     * Combina dos hash javascript nativos
     */
    merge: function(hashOne, hashTwo) {
        return $H(hashOne).merge($H(hashTwo)).toObject();
    },

    /**
     * Agrega al nombre del objeto y el atributo un número aleatorio
     */
    randomizeIdsAndNames: function(cssSelector, objectName, attributeNames) {
        $$(cssSelector).each(function(e) {
            var rand = new Number(Math.random()).toString().match(/0\.(\d+)/)[1];
            var input;
            var count = 0;

            while((input = e.down('input.' + objectName, count))) {
                input.writeAttribute('id', objectName + '_' +
                    attributeNames[count] + '_' + rand);
                input.writeAttribute('name', objectName + '[' +
                    attributeNames[count] + '_' + rand + ']');
                count++;
            }
        });
    },

    /**
     * Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
     * único generado con la fecha y un número incremental
     */
    replaceIds: function(s, regex){
        return s.gsub(regex, new Date().getTime() + State.newIdCounter++);
    }
}

// Funciones ejecutadas cuando se carga cada página
Event.observe(window, 'load', function() {
    document.on('ajax:after', function(e) { Helper.showLoading(e); });
    document.on('ajax:complete', function(e) { Helper.hideLoading(e); });

    document.on('keydown', function(e) {
        if ((e.keyCode || e.which) == 32 && e.ctrlKey) {
            Search.show();
            Event.stop(e);
        }
    });

    document.on('click', 'a[data-event]', function(event, element) {
        if(event.stopped) return;
        var eventName =
            element.readAttribute('data-event').dasherize().camelize();

        if(EventHandler.eventList.include(eventName)) {
            EventHandler[eventName](element);
            Event.stop(event);
        }
    });

    document.on('change', 'form', function(event, element) {
        if(!element.hasClassName('no_observe_changes')) {
            State.unsavedData = true;
        }
    });

    document.on('submit', function() {State.unsavedData = false;});

    // Cuando se remueve o se oculta un papel de trabajo reutilizar el código
    document.on("item:removed", '.work_paper', function(event, element) {
        var workPaperCode = element.down('input[name$="[code]"]').getValue();

        if(workPaperCode == lastWorkPaperCode) {
          lastWorkPaperCode = lastWorkPaperCode.previous(2);
        }
    });

    if($('app_content')) {
        Observer.attachToAppContent();
        
        Event.observe('app_content', 'mouseover', function(event) {
            var e = Event.findElement(event, 'img');

            if(e && e.hasClassName('change_on_hover')) {
                HTMLUtil.replaceWithHoverImage(e);
            }
        });

        Event.observe('app_content', 'mouseout', function(event) {
            var e = Event.findElement(event, 'img');

            if(e && e.hasClassName('change_on_hover')) {
                HTMLUtil.replaceWithNormalImage(e);
            }
        });
    }

    if($('menu_container') && !Prototype.Browser.MobileSafari) {
        Observer.attachToMenu();
    } else if($('mobile_menu')) {
        Observer.attachToMobileMenu();
    }

    // Mensajes diferidos
    if(Object.isArray(State.showMessages)) {
        $A(State.showMessages).each(function(messageData) {
            var time = messageData.get('time');
            var message = messageData.get('message');
            var expired = messageData.get('expired');

            messageData.set('timer_id',
                Helper.showMessage.delay(time, message, expired));
        });
    }

    Ajax.Responders.register({
        // Reinicia los timers con los mensajes diferidos
        onCreate: function() {
            $A(State.showMessages).each(function(messageData) {
                if(!State.sessionExpire) {
                    window.clearTimeout(messageData.get('timer_id'));
                    $('time_left').hide();

                    var time = messageData.get('time');
                    var message = messageData.get('message');
                    var expired = messageData.get('expired');

                    messageData.set('timer_id',
                        Helper.showMessage.delay(time, message, expired));
                }
            });
        }
    });

    if(!Prototype.Browser.MobileSafari) {
        $w('menu menu_level_1 menu_level_2').each(function(e) {
            if($(e)) { Element.show(e); }
        });
    }

    Helper.updateDimensions();
});

Event.observe(window, 'resize', function() {
    Helper.updateDimensions();
});

// Funciones que se agregan a todos lo elementos
Element.addMethods({
    downForIdFromName: function(element) {
        var e = $(element);
        var id = -1;
        var index = 0;

        do {
            var name = e.down('*[name]', index++).readAttribute('name');

            if(name.match(/.*\[(\d+)\]/)) {
                id = name.match(/.*\[(\d+)\]/)[1];
            }
        } while(name && id == -1);

        return id != -1 ? id : null;
    },
    resetToOriginalText: function(element) {
        var originalText = $(element).retrieve('original_text')

        if(originalText) {$(element).update(originalText);}
    },
    restoreStyleProperty: function(element, property) {
        var oldValue = element.retrieve('old_' + property);
        var newStyle = $H();

        if(!Object.isUndefined(oldValue)) {
            newStyle.set(property, oldValue);
            element.setStyle(newStyle.toObject());
        }
    },
    showOrHide: function(element, options) {
        Effect.toggle(element, 'slide', Util.merge({duration: 0.5}, options));
    },
    storeStyleProperty: function(element, property) {
        element.store('old_' + property, element.getStyle(property));
    },
    toggleContent: function(element, originalText, alternateText) {
        var e = $(element);

        e.store('original_text', originalText);
        e.store('alternate_text', alternateText);

        e.update(e.innerHTML == originalText ? alternateText : originalText);
    }
});

// Verifica antes de cerrar la ventana que los datos no hayan cambiado
window.onbeforeunload = function () {
    if (State.unsavedData) {
        $$('form').each(function(form) {
            Form.getElements(form).each(function(e) {
                if(e.retrieve('reset_value')) {
                    e.setValue(e.retrieve('reset_value'));
                }
            });
        });

        return State.unsavedDataWarning;
    } else {
        return undefined;
    }
}.bind(this);

Number.prototype.rnd = function() {
    return Math.floor(Math.random() * this + 1)
}

String.prototype.next = function(padded) {
    if(this.match(/\d+$/)) {
        var currentNumber = parseInt(this.match(/\d+$/).first(), 10);

        return this.replace(/\d+$/, (currentNumber + 1).toPaddedString(padded || 0));
    } else {
        return this;
    }
}

String.prototype.previous = function(padded) {
    if(this.match(/\d+$/)) {
        var currentNumber = parseInt(this.match(/\d+$/).first(), 10);

        return this.replace(/\d+$/, (currentNumber - 1).toPaddedString(padded || 0));
    } else {
        return this;
    }
}