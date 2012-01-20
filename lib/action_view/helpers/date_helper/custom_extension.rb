module ActionView
  module Helpers
    module DateHelper
      module CustomExtension
        def extended_distance_of_time_in_words(from_time, to_time = 0, include_seconds = false, options = {})
          from_time = from_time.to_time if from_time.respond_to?(:to_time)
          to_time = to_time.to_time if to_time.respond_to?(:to_time)
          distance_in_minutes = (((to_time - from_time).abs)/60).round

          I18n.with_options :locale => options[:locale], :scope => 'datetime.distance_in_words' do |locale|
            case distance_in_minutes
              when 10080..11519    then locale.t :x_weeks,        :count => 1
              when 11520..43199    then locale.t :about_x_weeks,  :count => (distance_in_minutes.to_f / 10080.0).round
              else
                distance_of_time_in_words(from_time, to_time, include_seconds, options)
            end
          end
        end
      end
    end
  end
end