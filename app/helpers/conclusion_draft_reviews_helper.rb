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
      icon('fas', 'file', title: t('conclusion_draft_review.new_conclusion_final_review')),
      *(args << html_options)
    )
  end

  def show_has_final_info
    show_info(t('conclusion_draft_review.has_final_review'), class: 'text-danger')
  end

  def sorted_best_practice_comments_for conclusion_review
    review       = conclusion_review.review
    bpcs         = review.best_practice_comments
    grouped_cois = review.grouped_control_objective_items_by_best_practice

    sorted_bpcs = grouped_cois.map do |best_practice, cois|
      bpcs.detect do |bpc|
        bpc.best_practice_id == best_practice.id
      end
    end

    sorted_bpcs.compact
  end

  def best_practice_comments_form conclusion_review
    simple_form_for conclusion_review do |f|
      render 'best_practice_comments', f: f, readonly: false
    end
  end

  def main_recommendations_for conclusion_review
    result = []
    review = conclusion_review.review

    review.grouped_control_objective_items.each do |process_control, cois|
      cois.sort.each do |coi|
        coi.weaknesses.not_revoked.sort_for_review.each do |w|
          if w.audit_recommendations.present?
            result << w.audit_recommendations.strip
          end
        end
      end
    end

    result.join "\r\n\r\n"
  end

  def recipients_for conclusion_review
    review  = conclusion_review.review
    audited = review.review_user_assignments.map(&:user).select &:can_act_as_audited?

    audited.map { |a| [a.last_name, a.name].join ', ' }.join "\r\n"
  end
end
