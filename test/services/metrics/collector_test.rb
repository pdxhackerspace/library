require 'test_helper'

module Metrics
  class CollectorTest < ActiveSupport::TestCase
    include MetricsTestHelper

    setup do
      @text = with_metrics do
        JobRecorder.record('Loans::OverdueNagJob', 'mailers', 0.3, success: true)
        RequestRecorder.record({ controller: 'HomeController', action: 'index', status: 200 }, 0.05)
        Collector.new.call
      end
    end

    test 'every collector succeeds' do
      Collector::SECTIONS.each do |section|
        assert_includes @text, %(library_scrape_collector_success{collector="#{section}"} 1), "#{section} failed"
      end
    end

    test 'reports catalog, user and loan counts' do
      assert_includes @text, "library_users #{User.count}\n"
      assert_includes @text, %(library_users_by_role{role="admin"} #{User.admins.count})
      assert_includes @text, "library_books #{Book.count}\n"
      assert_includes @text, "library_book_copies #{Book.sum(:copies_count)}\n"
      assert_includes @text, %(library_loans{state="active"} #{Loan.active.count})
      assert_includes @text, %(library_loans{state="overdue"} #{Loan.overdue.count})
      assert_includes @text, "library_api_keys #{ApiKey.count}\n"
      assert_includes @text, %(library_api_key_last_used_timestamp_seconds{name="RAG indexer"})
    end

    test 'reports runtime and database info' do
      assert_includes @text, %(library_info{version="#{AppInfo.version}")
      assert_includes @text, 'library_db_pool_connections{state="size"}'
      assert_match(/^library_db_size_bytes \d+$/, @text)
    end

    test 'reports sidekiq state' do
      assert_includes @text, '# TYPE library_sidekiq_processed_total counter'
      assert_match(/^library_sidekiq_enqueued \d+$/, @text)
      assert_includes @text, 'library_sidekiq_processes '
    end

    test 'reports recorded jobs and requests' do
      assert_includes @text,
                      'library_job_executions_total{job="Loans::OverdueNagJob",queue="mailers",status="success"} 1'
      assert_includes @text, 'library_job_duration_seconds_count{job="Loans::OverdueNagJob",queue="mailers"} 1'
      assert_includes @text, 'library_http_requests_total{controller="HomeController",action="index",status="200"} 1'
      assert_includes @text, 'library_http_request_duration_seconds_count{controller="HomeController",action="index"} 1'
    end

    test 'a failing section is reported without breaking the others' do
      text = with_metrics do
        collector = Collector.new
        collector.define_singleton_method(:collect_sidekiq) { raise 'redis down' }
        collector.call
      end

      assert_includes text, 'library_scrape_collector_success{collector="sidekiq"} 0'
      assert_includes text, 'library_scrape_collector_success{collector="application"} 1'
      assert_includes text, "library_books #{Book.count}\n"
    end
  end
end
