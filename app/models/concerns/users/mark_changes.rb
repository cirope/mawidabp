module Users::MarkChanges
  extend ActiveSupport::Concern

  included do
    after_save :reset_important_change
  end

  def is_an_important_change
    unless @__iaic_first_access
      @is_an_important_change = true
      @__iaic_first_access = true
    end

    @is_an_important_change
  end

  def is_an_important_change= is_an_important_change
    @__iaic_first_access = true

    @is_an_important_change = is_an_important_change
  end

  private

    def reset_important_change
      self.is_an_important_change = true
    end
end
