class FileUploader < CarrierWave::Uploader::Base
  storage :file
  after :remove, :delete_empty_upstream_dirs

  def store_dir
    guess_path
  end

  def extension_allowlist
    FILE_UPLOADS_CONSTRAINTS&.fetch 'extensions', nil
  end

  def size_range
    size_limit = FILE_UPLOADS_CONSTRAINTS&.fetch 'size_limit', nil

    1.byte..size_limit.megabytes if size_limit
  end

  private

    def organization_id_path organization_id = Current.organization&.id
      ('%08d' % (organization_id || 0)).scan(/\d{4}/).join('/')
    end

    def guess_path organization_id = Current.organization&.id
      path = path_for model.organization_id || organization_id

      File.exist?(path) ? path : try_corporate_path
    end

    def path_for organization_id
      id = ('%08d' % model.id).scan(/\d{4}/).join '/'

      File.join RELATIVE_PRIVATE_PATH, organization_id_path(organization_id), model.class.to_s.underscore.pluralize, id
    end

    def try_corporate_path
      path         = nil
      organization = Current.organization

      if organization && organization.corporate?
        organization_ids = organization.group.organizations.pluck 'id'
        posible_paths    = organization_ids.map { |organization_id| path_for organization_id }

        path = posible_paths.detect { |path| File.exist? path }
      end

      path || path_for(organization&.id)
    end

    def delete_empty_upstream_dirs
      Dir.delete(store_dir) if Dir.empty?(store_dir)

      parent_dir = File.dirname(store_dir)

      Dir.delete(parent_dir) if Dir.empty?(parent_dir)
    end
end
