require 'test_helper'

module Books
  class SaveCoverUploadTest < ActiveSupport::TestCase
    def cover_upload(name = 'cover.png', content_type = 'image/png')
      Rack::Test::UploadedFile.new(file_fixture(name), content_type)
    end

    def save_params(book, extra = {})
      { title: book.title, author_names: book.authors.pluck(:name) }.merge(extra)
    end

    test 'attaches uploaded cover photos' do
      book = books(:pragmatic)

      assert Books::Save.new(book, save_params(book, cover_uploads: ['', cover_upload])).call

      assert_equal(['cover.png'], book.reload.covers.map { |cover| cover.filename.to_s })
    end

    test 'rejects uploads that are not images' do
      book = books(:pragmatic)

      upload = cover_upload('not_an_image.txt', 'text/plain')

      assert_not Books::Save.new(book, save_params(book, title: 'Changed', cover_uploads: [upload])).call

      assert_includes book.errors.full_messages.to_sentence, 'must be a JPEG, PNG, WebP, or GIF image'
      assert_not book.reload.covers_attached?
      assert_not_equal 'Changed', book.title
    end

    test 'removes selected covers' do
      book = books(:pragmatic)
      book.covers.attach(io: file_fixture('cover.png').open, filename: 'old.png', content_type: 'image/png')
      cover_id = book.covers.attachments.first.id

      assert Books::Save.new(book, save_params(book, remove_cover_ids: [cover_id.to_s])).call

      assert_not book.reload.covers_attached?
    end

    test 'removing covers does not re-attach lookup covers' do
      book = books(:pragmatic)
      book.covers.attach(io: file_fixture('cover.png').open, filename: 'old.png', content_type: 'image/png')
      cover_id = book.covers.attachments.first.id

      assert Books::Save.new(book, save_params(book, remove_cover_ids: [cover_id.to_s],
                                                     pending_cover_urls: ['https://covers.example.com/old.png'])).call

      assert_not book.reload.covers_attached?
      assert_not_requested :get, 'https://covers.example.com/old.png'
    end
  end
end
