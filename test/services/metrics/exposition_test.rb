require 'test_helper'

module Metrics
  class ExpositionTest < ActiveSupport::TestCase
    test 'renders a gauge without labels' do
      out = Exposition.new
      out.gauge('library_things', 'How many things.', 3)

      assert_equal "# HELP library_things How many things.\n# TYPE library_things gauge\nlibrary_things 3\n", out.to_s
    end

    test 'renders labelled counters and escapes label values' do
      out = Exposition.new
      out.counter('library_x_total', 'X.', [[{ name: %(a "b"\\c\nd) }, 2]])

      assert_includes out.to_s, %(library_x_total{name="a \\"b\\"\\\\c\\nd"} 2)
      assert_includes out.to_s, '# TYPE library_x_total counter'
    end

    test 'omits families with no samples' do
      out = Exposition.new
      out.gauge('library_empty', 'Nothing.', [])
      out.histogram('library_empty_seconds', 'Nothing.', {})

      assert_equal "\n", out.to_s
    end

    test 'renders histograms with cumulative buckets' do
      out = Exposition.new
      series = { { job: 'A' } => { buckets: { 0.1 => 1, 1.0 => 2 }, sum: 3.5, count: 4 } }
      out.histogram('library_d_seconds', 'D.', series, bounds: [0.1, 1.0])
      text = out.to_s

      assert_includes text, 'library_d_seconds_bucket{job="A",le="0.1"} 1'
      assert_includes text, 'library_d_seconds_bucket{job="A",le="1.0"} 3'
      assert_includes text, 'library_d_seconds_bucket{job="A",le="+Inf"} 4'
      assert_includes text, 'library_d_seconds_sum{job="A"} 3.5'
      assert_includes text, 'library_d_seconds_count{job="A"} 4'
    end

    test 'formats nil and non-finite values' do
      out = Exposition.new
      out.gauge('library_n', 'N.', [[{}, nil], [{ k: 'inf' }, Float::INFINITY]])

      assert_includes out.to_s, "library_n NaN\n"
      assert_includes out.to_s, 'library_n{k="inf"} +Inf'
    end
  end
end
