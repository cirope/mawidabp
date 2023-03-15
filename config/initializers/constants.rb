# Variable para setear cookies de session
COOKIES_DOMAIN = ".#{ENV['APP_HOST'].sub /:.*/, ''}"
SHARED_SESSION = ENV['SHARED_SESSION'] == 'true'
# Dirección del correo electrónico de soporte
SUPPORT_EMAIL = 'soporte@mawidabp.com'.freeze
# Ruta relativa directorio privado de almacenamiento de archivos
RELATIVE_PRIVATE_PATH =
  if Rails.env.test?
    File.join('test', 'private').freeze
  else
    File.join('private').freeze
  end
# Ruta absoluta directorio privado de almacenamiento de archivos
PRIVATE_PATH = File.join(Rails.root, RELATIVE_PRIVATE_PATH).freeze
# Ruta al directorio temporal
TEMP_PATH = File.join(Rails.root, 'tmp').freeze
# Prefijo de la organización para administrar grupos
APP_ADMIN_PREFIXES = ['admin', 'www'].freeze
# Variable con los idiomas disponibles (Debería reemplazarse con
# I18.available_locales cuando se haya completado la traducción a Inglés)
AVAILABLE_LOCALES = [:es, :en].freeze
# Cantidad de días en los que es posible cambiar la contraseña luego de un
# blanqueo
BLANK_PASSWORD_STALE_DAYS = 3
# Cantidad de dias anteriores al cierre de un informe definitivo en los que el
# sistema notificará su proximidad
CONCLUSION_FINAL_REVIEW_EXPIRE_DAYS = 7
# Expresión regular para validar direcciones de correo
EMAIL_REGEXP = /\A[a-z0-9'._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\Z/i
# Cantidad máxima de observaciones por PDF
FINDING_MAX_PDF_ROWS = 100
# Cantidad de días anteriores al vencimiento de una observación en los que el
# sistema notificará su proximidad
FINDING_WARNING_EXPIRE_DAYS = 7
# Cantidad de días a los que se debe enviar una nueva solicitud de confirmación
FINDING_DAYS_FOR_SECOND_NOTIFICATION = 1
# Fecha inicial para el envío de correo con resumen de observaciones
FINDING_INITIAL_BRIEF_DATE = Date.new 2018, 1, 1
# Opciones para crear claves foráneas
FOREIGN_KEY_OPTIONS={ on_delete: :restrict, on_update: :restrict }
# Días a los que se consideran anticuadas las notificaciones
NOTIFICATIONS_STALE_DAYS = 2
# Deshabilitar notificación de observaciones vencidas
DISABLE_FINDINGS_EXPIRATION_NOTIFICATION = ENV['DISABLE_FINDINGS_EXPIRATION_NOTIFICATION'] == 'true'
# Cadena para separar las enumeraciones cuando son concatenadas
APP_ENUM_SEPARATOR = ' / '.freeze
# Márgenes a dejar en los reportes generados en PDF (T, R, B, L)
PDF_MARGINS = [25, 20, 30, 25].freeze
# Tamaño de la página a usar en los reportes generados en PDF
PDF_PAPER = 'A4'.freeze
# Logo para el pié de página de los PDFs
PDF_LOGO = File.join(Rails.root, 'app', 'assets', 'images', 'logo_pdf.png').freeze
# Dimensiones del logo en pixels, primero el ancho y luego el alto
PDF_LOGO_SIZE = [350, 51].map { |size| (size / 6.0).round }
# Escala del logo
PDF_LOGO_FACTOR = 1.0
# Tamaño de fuente en los PDF
PDF_FONT_SIZE = 11
# Tamaño de fuente de lo escrito en la cabecera
PDF_HEADER_FONT_SIZE = 10
# Prefijo para los archivos que no se pueden acceder sin estar autenticado
PRIVATE_FILES_PREFIX = 'private'.freeze
# Expresión regular para dividir términos en una búsqueda (operador AND)
SPLIT_AND_TERMS_REGEXP = /\s+y\s+|\s*[;]\s*|\s+AND\s+/i
# Expresión regular para dividir términos en una búsqueda (operador OR)
SPLIT_OR_TERMS_REGEXP = /\s+o\s+|\s*[,]\s*|\s+OR\s+/i
# Ruta a un archivo para realizar las pruebas
TEST_FILE = File.join('..', '..', 'public', '500.html').freeze
# Ruta a un archivo para realizar las pruebas (ruta completa)
TEST_FILE_FULL_PATH = File.join(Rails.root, 'public', '500.html').freeze
# Ruta a una imagen para realizar las pruebas (ruta completa)
TEST_IMAGE_FULL_PATH = File.join(Rails.root, 'test/test_images', 'logo.png').freeze
# Dirección base para formar los links absolutos
URL_HOST = (ENV['APP_HOST'] + (Rails.env.development? ? ':3000' : '')).freeze
# Expresión regular para separar términos en las cadenas de búsqueda (operador
# AND)
SEARCH_AND_REGEXP = /\s*[;]+\s*|\s+AND\s+|\s+Y\s+/i
# Expresión regular para separar términos en las cadenas de búsqueda (operador
# OR)
SEARCH_OR_REGEXP = /\s*[,\+]+\s*|\s+OR\s+|\s+O\s+/i
# Expresión regular para identificar fechas
SEARCH_DATE_REGEXP = /^\s*\d{1,2}\/\d{1,2}\/(\d{2}|\d{4})\s*$/
# Operadores permitidos en la búsqueda
SEARCH_ALLOWED_OPERATORS = HashWithIndifferentAccess.new({
    /^\s*>[^=]?\s+/ => '>',
    /^\s*<[^=]?\s+/ => '<',
    /^\s*(>=|desde|since)\s+/i => '>=',
    /^\s*(<=|hasta|to)\s+/i => '<=',
    /^\s*[^<>]=\s+/ => '='
})
# Adaptador PostgreSQL en uso
ORACLE_ADAPTER = ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced' rescue nil
POSTGRESQL_ADAPTER = ActiveRecord::Base.connection.adapter_name == 'PostgreSQL' rescue !ORACLE_ADAPTER
# Limite de filas en reportes para servir en real-time
SEND_REPORT_EMAIL_AFTER_COUNT = 100
# Planes de licencias
LICENSE_PLANS = if RUBY_VERSION >= '3.1.0'
                  YAML.load(
                    File.read('config/license_plans.yml'), aliases: true
                  )[Rails.env].with_indifferent_access.freeze
                else
                  YAML.load(
                    File.read('config/license_plans.yml')
                  )[Rails.env].with_indifferent_access.freeze
                end
# Redis config
REDIS_HOST = ENV['REDIS_HOST'] || 'localhost'
REDIS_PORT = ENV['REDIS_PORT'] || '6379'
# Tamaño de fuente en los RTF
RTF_FONT_SIZE = 22
