class BooksController < ApplicationController
  include BookFormLists

  before_action :require_login
  before_action :require_editor, except: %i[index show checkout return]
  before_action :set_book, only: %i[show edit update destroy checkout return]
  before_action :set_lookup_token, only: %i[new edit]

  def index
    @books = Book.includes(:authors, :isbns, :location, loans: :user).ordered
    @active_loans = Loan.active.includes(:book, :user).recent
  end

  def show; end

  def new
    @book = Book.new
    prepare_new_book_lists
  end

  def edit
    prepare_edit_book_lists
  end

  def create
    @book = Book.new
    save_book(create_redirect: true)
  end

  def update
    save_book(create_redirect: false)
  end

  def scan_isbn
    if params[:photo].blank?
      render json: { isbns: [], error: 'No photo uploaded.' }, status: :unprocessable_content
      return
    end

    isbns = IsbnScanning::BarcodeReader.call(params[:photo])
    render json: { isbns: isbns }
  end

  def lookup_metadata
    result = Books::Metadata::EnqueueLookup.call(params)
    render json: result.except(:http_status), status: result[:http_status]
  end

  def destroy
    if @book.on_loan?
      redirect_to @book, alert: 'Return the book before deleting it.'
    else
      @book.destroy!
      redirect_to books_path, notice: 'Book removed from the library.'
    end
  end

  def checkout
    if @book.on_loan?
      redirect_to @book, alert: 'This book is already on loan.'
      return
    end

    loan = @book.loans.build(
      user: current_user,
      checked_out_at: Time.current,
      due_on: Date.current + SiteSetting.instance.loan_period
    )

    if loan.save
      redirect_to @book, notice: 'Book checked out to you.'
    else
      redirect_to @book, alert: loan.errors.full_messages.to_sentence
    end
  end

  def return
    loan = @book.active_loan

    if loan.nil?
      redirect_to @book, alert: 'This book is not on loan.'
    elsif loan.user_id == current_user.id || current_user.admin?
      loan.return!
      redirect_to @book, notice: 'Book returned.'
    else
      redirect_to @book, alert: 'Only the borrower or an admin can return this book.'
    end
  end

  private

  def set_book
    @book = Book.includes(:authors, :isbns, :book_authors, :subjects, :book_subjects, :location,
                          covers_attachments: :blob).find(params.expect(:id))
  end

  def set_lookup_token
    @lookup_token = SecureRandom.uuid
  end

  def save_book(create_redirect:)
    @book.isbn_codes_list = book_params[:isbn_codes].presence || ['']
    @lookup_token = params[:lookup_token] if params[:lookup_token].present?

    if Books::Save.new(@book, book_params).call
      redirect_to @book, notice: create_redirect ? 'Book added to the library.' : 'Book updated.'
    else
      prepare_form_extras
      render(create_redirect ? :new : :edit, status: :unprocessable_content)
    end
  end
end
