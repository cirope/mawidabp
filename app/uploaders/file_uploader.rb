class FileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    guess_path
  end

  private

    def organization_id_path organization_id = Organization.current_id
      ('%08d' % (organization_id || 0)).scan(/\d{4}/).join('/')
    end

    def guess_path organization_id = Organization.current_id
      path = path_for model.organization_id || organization_id

      File.exist?(path) ? path : try_corporate_path
    end

    def path_for organization_id
      id = ('%08d' % model.id).scan(/\d{4}/).join '/'

      "private/#{organization_id_path(organization_id)}/#{model.class.to_s.underscore.pluralize}/#{id}"
    end

    def try_corporate_path
      path         = nil
      organization = Organization.find_by id: Organization.current_id

      if organization && organization.corporate?
        organization_ids = organization.group.organizations.pluck 'id'
        posible_paths    = organization_ids.map { |organization_id| path_for organization_id }

        path = posible_paths.detect { |path| File.exist? path }
      end

      path || path_for(Organization.current_id)
    end
end
