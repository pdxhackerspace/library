module Api
  module V1
    class CatalogController < BaseController
      CONTENT_TYPE = 'application/jsonl; charset=utf-8'.freeze

      def index
        since = parse_since
        return if performed?
        return unless stale?(etag: [catalog_version, since], public: false)

        feed = Books::CatalogFeed.new(url_options: url_options_for_feed, since: since)
        render plain: feed.call, content_type: CONTENT_TYPE
      end

      private

      def parse_since
        raw = params[:since].presence
        return nil unless raw

        Time.zone.iso8601(raw)
      rescue ArgumentError
        render json: { error: 'since must be an ISO 8601 timestamp, e.g. 2026-01-31T00:00:00Z' },
               status: :bad_request
        nil
      end

      def catalog_version
        [Book.count, Book.maximum(:updated_at), Location.maximum(:updated_at)]
      end

      # Prefer the canonical APP_BASE_URL so indexers get public links even when
      # they reach the app through an internal hostname.
      def url_options_for_feed
        return Rails.application.routes.default_url_options.symbolize_keys if ENV['APP_BASE_URL'].present?

        { host: request.host, port: request.optional_port, protocol: request.protocol }
      end
    end
  end
end
