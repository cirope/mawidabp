module ConclusionDraftReviewsHelper
  # Devuelve el HTML de un vínculo para crear un nuevo informe final
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_new_conclusion_final_review(*args)
    html_options = {:class => :image_link}
    options = {:label =>
        t(:'conclusion_draft_review.new_conclusion_final_review')}
    options.merge!(args.pop) if args.last.kind_of?(Hash)
    html_options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(image_tag('new_document.gif', :size => '22x20',
        :alt => options[:label], :title => options.delete(:label)),
      *(args << html_options))
  end

  def show_has_final_info
    show_info(t(:'conclusion_draft_review.has_final_review'), :class => :red)
  end
end