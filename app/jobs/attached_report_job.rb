class AttachedReportJob < ApplicationJob
  queue_as :default

  def perform args
    model           = args.fetch(:model_name).constantize
    query_methods   = args.fetch :query_methods, {}.to_json
    filename        = args.fetch :filename
    method_name     = args.fetch :method_name
    options         = args.fetch :options, {}
    user_id         = args.fetch :user_id
    organization_id = args.fetch :organization_id

    Current.organization = Organization.find organization_id

    scope        = build_scope_for model, query_methods
    report       = scope.send method_name, **options
    zip_file     = zip_report_with_filename report, filename
    extension    = File.extname filename
    new_filename = filename.sub(
      /#{Regexp.escape extension}$/,
      '.zip'
    )

    ReportMailer.attached_report(
      filename:        new_filename,
      file:            zip_file,
      user_id:         user_id,
      organization_id: organization_id
    ).deliver_later
  end

  private

    def build_scope_for model, raw_query_methods
      query_methods = JSON.parse(raw_query_methods).deep_symbolize_keys

      scope = model.unscoped # remove default orders

      query_methods.reject { |_, args| args.blank? }.each do |method, args|
        if [:where, :order, :select].include? method
          args.each do |query|
            arg   = query.is_a?(String) ? Arel.sql(query) : deep_convert_to_sym(query)
            scope = scope.send method, arg
          end
        elsif method == :group
          scope     = scope.send method, args
        else
          arguments = args.is_a?(String) ? [args] : deep_convert_to_sym(args)
          arguments = arguments.is_a?(Hash) ? [arguments] : arguments
          scope     = scope.send method, *arguments
        end
      end

      scope
    end

    def zip_report_with_filename report, filename
      tmp_file = Dir::Tmpname.create(filename) {}

      Zip::File.open(tmp_file, Zip::File::CREATE) do |zip|
        zip.get_output_stream(filename) { |f| f.write report }
      end

      tmp_file
    end

    def deep_convert_to_sym data
      case data
      when Hash
        data.map { |k, v| [k, deep_convert_to_sym(v)] }.to_h
      when Array
        data.map { |e| e.try(:to_sym) || deep_convert_to_sym(e) }
      when String
        data.to_sym
      else
        data
      end
    end
end
