module ConclusionDraftReviewsHelper
  # Devuelve el HTML de un vínculo para crear un nuevo informe final
  #
  # * <em>*args</em>:: Las mismas opciones que link_to sin la etiqueta
  def link_to_new_conclusion_final_review(*args)
    html_options = {}
    options = {}
    options.merge!(args.pop) if args.last.kind_of?(Hash)
    html_options.merge!(args.pop) if args.last.kind_of?(Hash)

    link_to(
      content_tag(:span, nil, class: 'icon glyphicon glyphicon-file',
        title: t('conclusion_draft_review.new_conclusion_final_review')),
      *(args << html_options)
    )
  end

  def show_has_final_info
    show_info(t('conclusion_draft_review.has_final_review'), class: 'text-danger')
  end

  def show_review_best_practice_comments?
    prefix = current_organization&.prefix

    SHOW_REVIEW_BEST_PRACTICE_COMMENTS &&
      ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS.include?(prefix)
  end

  def best_practice_comments_form conclusion_review
    simple_form_for conclusion_review do |f|
      render 'best_practice_comments', f: f, readonly: false
    end
  end
end
