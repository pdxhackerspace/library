module ApplicationHelper
  def bootstrap_class_for(flash_type)
    {
      success: 'success',
      notice: 'success',
      alert: 'danger',
      error: 'danger'
    }.fetch(flash_type.to_sym, flash_type.to_s)
  end

  def book_status_label(book)
    if book.available?
      tag.span('Available', class: 'badge text-bg-success-subtle')
    else
      tag.span('On loan', class: 'badge text-bg-warning-subtle')
    end
  end

  def ebook_link_for(book, css: 'link-secondary text-12')
    return if book.ebook_url.blank?

    link_to 'Ebook', book.ebook_url, class: css, target: '_blank', rel: 'noopener'
  end

  def copies_count_cell(count)
    count = count.to_i
    css = count == 1 ? 'text-secondary' : 'fw-medium'
    tag.span(count, class: "num #{css}")
  end
end
