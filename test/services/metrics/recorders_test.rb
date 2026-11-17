require 'test_helper'

module Metrics
  class RecordersTest < ActiveSupport::TestCase
    include MetricsTestHelper

    test 'job recorder accumulates outcomes, duration and buckets' do
      with_metrics do
        JobRecorder.record('Loans::DueReminderJob', 'mailers', 0.02, success: true)
        JobRecorder.record('Loans::DueReminderJob', 'mailers', 400.0, success: false)

        entry = JobRecorder.read.sole
        assert_equal 'Loans::DueReminderJob', entry[:job]
        assert_equal 'mailers', entry[:queue]
        assert_equal 1, entry[:success]
        assert_equal 1, entry[:failure]
        assert_in_delta 400.02, entry[:sum], 0.001
        assert_equal 1, entry[:buckets][0.025]
        assert_equal 1, entry[:buckets][:inf]

        job, status, = JobRecorder.last_runs.min_by { |row| row[1] }
        assert_equal 'Loans::DueReminderJob', job
        assert_equal 'failure', status
      end
    end

    test 'job recorder does nothing when metrics are disabled' do
      with_metrics(token: nil) do
        JobRecorder.record('X', 'default', 1.0, success: true)
      end
      with_metrics { assert_empty JobRecorder.read }
    end

    test 'middleware records success and failure and re-raises' do
      with_metrics do
        middleware = SidekiqMiddleware.new
        worker = Object.new
        job = { 'wrapped' => 'Books::MetadataLookupJob' }

        middleware.call(worker, job, 'default') { :ok }
        assert_raises(RuntimeError) { middleware.call(worker, job, 'default') { raise 'boom' } }

        entry = JobRecorder.read.sole
        assert_equal 'Books::MetadataLookupJob', entry[:job]
        assert_equal 1, entry[:success]
        assert_equal 1, entry[:failure]
      end
    end

    test 'request recorder aggregates per route' do
      with_metrics do
        payload = { controller: 'BooksController', action: 'index', status: 200, db_runtime: 20.0, view_runtime: 30.0 }
        RequestRecorder.record(payload, 0.2)
        RequestRecorder.record(payload.merge(status: 500), 0.3)

        route = RequestRecorder.read.sole
        assert_equal({ '200' => 1, '500' => 1 }, route[:statuses])
        assert_in_delta 0.5, route[:sum], 0.001
        assert_in_delta 0.04, route[:db], 0.001
        assert_in_delta 0.06, route[:view], 0.001
      end
    end

    test 'request recorder ignores the metrics endpoint' do
      with_metrics do
        RequestRecorder.record({ controller: 'MetricsController', action: 'show', status: 200 }, 0.1)

        assert_empty RequestRecorder.read
      end
    end
  end
end
