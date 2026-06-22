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

  def book_status_dot(book, title: nil)
    css = book.available? ? 'status-success' : 'status-warning'
    label = title || (book.available? ? 'Available' : 'On loan')
    tag.span('', class: "status-dot #{css}", title: label, aria: { label: label })
  end

  def book_cover_tag(book, size: :shelf, attachment: nil, **options)
    css_classes = book_cover_classes(size, options.delete(:class))
    alt = options.delete(:alt) { book.title }
    attachment ||= book.primary_cover

    if attachment
      image_tag attachment, class: css_classes, alt: alt, **options
    else
      book_cover_placeholder(book, css_classes, **options)
    end
  end

  def book_cover_classes(size, extra_class = nil)
    size_class = {
      shelf: 'book-cover--shelf',
      hero: 'book-cover--hero',
      thumb: 'book-cover--thumb'
    }.fetch(size)

    ['book-cover', size_class, extra_class].compact_blank.join(' ')
  end

  def book_cover_placeholder(book, css_classes, **)
    initial = book.title.to_s.strip.first&.upcase
    tag.div(class: "#{css_classes} book-cover--placeholder", **) do
      safe_join([
        tag.i('', class: 'bi bi-book book-cover__icon', aria: { hidden: true }),
        (tag.span(initial, class: 'book-cover__initial') if initial)
      ].compact)
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

  def nfc_tag_payload(book)
    Books::NfcTagPayload.call(book)
  end
end
