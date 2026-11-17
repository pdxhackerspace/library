require 'sidekiq/api'

module Metrics
  module Collectors
    module Application
      def collect_application
        collect_info
        collect_users
        collect_catalog
        collect_loans
        collect_api_keys
      end

      def collect_info
        @out.gauge('library_info', 'Build and runtime information.',
                   [[{ version: AppInfo.version, ruby_version: RUBY_VERSION, rails_version: Rails.version,
                       environment: Rails.env }, 1]])
        @out.gauge('library_process_start_time_seconds', 'Start time of the serving process, unix time.', Collector::BOOT_TIME)
      end

      def collect_users
        @out.gauge('library_users', 'Total users.', User.count)
        @out.gauge('library_users_by_role', 'Users by role.',
                   [[{ role: 'admin' }, User.admins.count],
                    [{ role: 'editor' }, User.editors.where(admin: false).count],
                    [{ role: 'member' }, User.where(admin: false, editor: false).count]])
        @out.gauge('library_users_by_auth_provider', 'Users by sign-in provider (local = password).',
                   User.group(:provider).count.map { |provider, n| [{ provider: provider.presence || 'local' }, n] })
        @out.gauge('library_users_with_slack', 'Users linked to a Slack account.', User.where.not(slack_uid: nil).count)
      end

      def collect_catalog
        collect_book_totals
        @out.gauge('library_authors', 'Authors.', Author.count)
        @out.gauge('library_subjects', 'Subjects.', Subject.count)
        @out.gauge('library_isbns', 'ISBN records.', Isbn.count)
        publishers = Book.where.not(publisher: [nil, '']).distinct.count(:publisher)
        @out.gauge('library_publishers', 'Distinct publishers.', publishers)
        @out.gauge('library_locations', 'Locations.', Location.count)
        @out.gauge('library_books_by_location', 'Books per location.', books_by_location)
        @out.gauge('library_stored_files', 'Active Storage blobs (covers).', ActiveStorage::Blob.count)
        @out.gauge('library_stored_bytes', 'Bytes held in Active Storage.', ActiveStorage::Blob.sum(:byte_size))
      end

      def collect_book_totals
        @out.gauge('library_books', 'Book records.', Book.count)
        @out.gauge('library_book_copies', 'Physical copies across all books.', Book.sum(:copies_count))
        @out.gauge('library_books_without_location', 'Books with no location.', Book.where(location_id: nil).count)
        @out.gauge('library_books_by_metadata_source', 'Books by where their metadata came from.',
                   Book.group(:metadata_source).count.map { |src, n| [{ source: src.presence || 'none' }, n] })
        @out.gauge('library_book_views', 'Sum of book page views.', Book.sum(:view_count))
        @out.gauge('library_book_nfc_views', 'Sum of book views via NFC tags.', Book.sum(:nfc_view_count))
        @out.gauge('library_book_borrows', 'Sum of book borrow counts.', Book.sum(:borrow_count))
        @out.gauge('library_books_last_updated_timestamp_seconds', 'Most recent book update, unix time.',
                   Book.maximum(:updated_at)&.to_f || 0)
      end

      def books_by_location
        names = Location.pluck(:id, :name).to_h
        Book.group(:location_id).count.filter_map do |id, n|
          [{ location: id ? names.fetch(id, 'unknown') : 'none' }, n]
        end
      end

      def collect_loans
        @out.gauge('library_loans', 'Loans by state (overdue and due_today are subsets of active).',
                   [[{ state: 'active' }, Loan.active.count], [{ state: 'overdue' }, Loan.overdue.count],
                    [{ state: 'due_today' }, Loan.due_today.count], [{ state: 'returned' }, Loan.returned.count]])
        oldest = Loan.overdue.minimum(:due_on)
        @out.gauge('library_loan_max_days_overdue', 'Days the most overdue loan is late (0 if none).',
                   oldest ? (Date.current - oldest).to_i : 0)
        @out.gauge('library_loans_by_borrower_active_max', 'Most active loans held by one user.',
                   Loan.active.group(:user_id).count.values.max || 0)
      end

      def collect_api_keys
        keys = ApiKey.ordered.to_a
        @out.gauge('library_api_keys', 'API keys.', keys.size)
        @out.gauge('library_api_key_last_used_timestamp_seconds', 'When each API key was last used, unix time.',
                   keys.map { |key| [{ name: key.name }, key.last_used_at&.to_f || 0] })
      end
    end
  end
end
