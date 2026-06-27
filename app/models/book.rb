class Book < ApplicationRecord
  belongs_to :location, optional: true

  has_many :loans, dependent: :destroy
  has_many :book_authors, -> { order(:position) }, dependent: :destroy, inverse_of: :book
  has_many :authors, through: :book_authors
  has_many :book_subjects, -> { order(:position) }, dependent: :destroy, inverse_of: :book
  has_many :subjects, through: :book_subjects
  has_many :isbns, dependent: :destroy
  has_many_attached :covers

  validates :title, presence: true
  validates :copies_count, numericality: { only_integer: true, greater_than: 0 }
  validates :ebook_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validate :must_have_at_least_one_author

  before_validation :normalize_ebook_url

  scope :ordered, -> { order(:title) }
  scope :recently_added, ->(limit = 12) { order(created_at: :desc).limit(limit) }
  scope :random_sample, ->(limit = 12) { order(Arel.sql('RANDOM()')).limit(limit) }

  scope :popular, lambda { |limit = 12|
    popular_ids = Loan.group(:book_id).order(Arel.sql('COUNT(*) DESC')).limit(limit).pluck(:book_id)
    popular_ids.empty? ? none : in_order_of(:id, popular_ids)
  }

  attr_writer :author_names_text, :author_names_list, :subject_names_list, :isbn_codes_list

  def active_loan
    loans.where(returned_at: nil).order(checked_out_at: :desc).first
  end

  def available?
    active_loan.nil?
  end

  def on_loan?
    !available?
  end

  def authors_label
    book_authors.includes(:author).map { |book_author| book_author.author.name }.join(', ')
  end

  def isbn_codes
    isbns.order(:id).pluck(:code)
  end

  def author_names_text
    @author_names_text || author_names_list.compact_blank.join("\n")
  end

  def author_names_list
    return @author_names_list if @author_names_list

    names = book_authors.includes(:author).map { |book_author| book_author.author.name }
    names.presence || ['']
  end

  def isbn_codes_list
    @isbn_codes_list || isbn_codes
  end

  def covers_attached?
    covers.attachments.any?
  end

  def primary_cover
    covers_attachments = covers.attachments
    return nil if covers_attachments.none?

    covers_attachments.order(:id).first
  end

  def subjects_label
    book_subjects.includes(:subject).map { |book_subject| book_subject.subject.name }.join(', ')
  end

  def subject_names_list
    return @subject_names_list if @subject_names_list

    names = book_subjects.includes(:subject).map { |book_subject| book_subject.subject.name }
    names.presence || ['']
  end

  METADATA_SOURCE_LABELS = {
    'open_library' => 'Open Library',
    'google_books' => 'Google Books'
  }.freeze

  def metadata_imported?
    metadata_source.present?
  end

  def metadata_source_label
    METADATA_SOURCE_LABELS.fetch(metadata_source, metadata_source&.humanize)
  end

  private

  def normalize_ebook_url
    self.ebook_url = ebook_url.to_s.strip.presence
  end

  def must_have_at_least_one_author
    names = Books::AuthorNames.parse(author_names_text)
    return if names.any?
    return if book_authors.any?

    errors.add(:base, 'must include at least one author')
  end
end
