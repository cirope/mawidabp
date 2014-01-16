module SettingsHelper
  include Parameters::Risk
  include Parameters::Priority
  include Parameters::Relevance
  include Parameters::Qualification

  def relevance_field(form, *args)
    options = args.extract_options!

    collection = RELEVANCE_TYPES.map do |k,v|
      [[t("relevance_types.#{k}"),"(#{v})"].join(' '), v]
    end

    form.input :relevance, options.merge(collection: collection)
  end

  def qualification_field(form, field, *args)
    options = args.extract_options!

    collection = QUALIFICATION_TYPES.map do |k,v|
      [[t("qualification_types.#{k}"), "(#{v})"].join(' '), v]
    end

    form.input field, options.merge(collection: collection)
  end

  def risk_field(form, *args)
    options = args.extract_options!

    collection = RISK_TYPES.map do |k,v|
      [[t("risk_types.#{k}"), "(#{v})"].join(' '), v]
    end

    form.input :risk, options.merge(collection: collection)
  end

  def priority_field(form, *args)
    options = args.extract_options!

    collection = PRIORITY_TYPES.map do |k,v|
      [[t("priority_types.#{k}"), "(#{v})"].join(' '), v]
    end

    form.input :priority, options.merge(collection: collection)
  end
end
