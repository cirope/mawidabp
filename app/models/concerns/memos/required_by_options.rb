module Memos::RequiredByOptions
  extend ActiveSupport::Concern

  included do
    REQUIRED_BY_OPTIONS = [
      'Sindicatura General de la Nación',
      'Auditoria General de la Nación',
      'Banco Central de la República Argentina',
      'Auditor Externo'
    ]
  end
end
