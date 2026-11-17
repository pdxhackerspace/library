require 'sidekiq/api'

module Metrics
  module Collectors
    module Requests
      def collect_requests
        routes = RequestRecorder.read
        @out.counter('library_http_requests_total', 'Controller requests by route and status.',
                     routes.flat_map { |r| status_samples(r) })
        @out.histogram('library_http_request_duration_seconds', 'Controller request time in seconds.',
                       routes.to_h { |r| [route_labels(r), histogram_data(r, r[:statuses].values.sum)] })
        @out.counter('library_http_request_db_seconds_total', 'Time spent in the database, by route.',
                     routes.map { |r| [route_labels(r), r[:db].round(6)] })
        @out.counter('library_http_request_view_seconds_total', 'Time spent rendering views, by route.',
                     routes.map { |r| [route_labels(r), r[:view].round(6)] })
      end

      def status_samples(route)
        route[:statuses].map { |code, n| [route_labels(route).merge(status: code), n] }
      end

      def route_labels(route)
        { controller: route[:controller], action: route[:action] }
      end
    end
  end
end
