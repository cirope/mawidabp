module Organizations::Options
  extend ActiveSupport::Concern

  included do
    attr_accessor :option_type

    after_create_commit :create_options
  end

  OPTIONS_TYPES = [
    'manual_scores',
    'control_objective_item_scores',
    'relevance',
    'priorities',
    'risks'
  ]

  DEFAULT_SCORES = {
    satisfactory:                   100,
    needs_minor_improvements:       80,
    needs_improvement:              60,
    needs_significant_improvements: 40,
    unsatisfactory:                 20
  }

  OPTIONS_TYPES.each do |option|
    define_method(option) do |date: nil|
      options_for type: option, date: date
    end

    define_method("#{option}_text_for") do |date: nil, value: nil|
      options_text_for type: option, date: date, value: value
    end
  end

  def current_options_by type
    options = options_by type

    options.present? ? sorted_options(options.first&.last) : []
  end

  def options_by type
    if options&.dig(type)
      options[type].sort_by { |score, value| score.to_i }.reverse.to_h
    end
  end

  def create_options
    update! options: default_options
  end

  module ClassMethods
    def default_options date
      epoch   = date.to_i
      options = {
        manual_scores:                 { epoch => Organization::DEFAULT_SCORES         },
        control_objective_item_scores: { epoch => Setting::DEFAULT_QUALIFICATION_TYPES },
        relevance:                     { epoch => Setting::DEFAULT_RELEVANCE_TYPES     },
        priorities:                    { epoch => Setting::DEFAULT_PRIORITY_TYPES      },
        risks:                         { epoch => Setting::DEFAULT_RISK_TYPES          }
      }
    end
  end

  private

    def options_for type:, date:
      epoch = (date || Time.zone.now).to_i

      sorted_options(
        options_by(type)&.detect { |date, values| date.to_i <= epoch }&.last
      )
    end

    def options_text_for type:, date:, value:
      options = options_for type: type, date: date

      options.invert.dig value.to_i
    end

    def sorted_options options
      if options.present?
        options.sort_by { |option, value| value.to_i }.reverse.to_h
      else
        {}
      end
    end

    def default_options
      epoch = Time.zone.now.to_i

      OPTIONS_TYPES.each_with_object({}) do |option, result|
        result[option.to_sym] = { epoch => send("default_#{option}") }
      end
    end

    def default_manual_scores
      translate_keys Organization::DEFAULT_SCORES, 'options.manual_scores.defaults'
    end

    def default_control_objective_item_scores
      translate_keys Parameters::Qualification::DEFAULT_QUALIFICATION_TYPES, 'qualification_types'
    end

    def default_relevance
      translate_keys Parameters::Relevance::DEFAULT_RELEVANCE_TYPES, 'relevance_types'
    end

    def default_priorities
      translate_keys Parameters::Priority::DEFAULT_PRIORITY_TYPES, 'priority_types'
    end

    def default_risks
      translate_keys Parameters::Risk::DEFAULT_RISK_TYPES, 'risk_types'
    end

    def translate_keys defaults, i18n_path
      defaults.each_with_object({}) do |(key, value), result|
        translated_key = I18n.t "#{i18n_path}.#{key}"

        result[translated_key] = value
      end
    end
end
