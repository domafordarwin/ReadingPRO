# frozen_string_literal: true

class QueryAnalyzer
  # Phase 3.4.4: Database query analysis and optimization service
  #
  # Tracks and analyzes all database queries to identify optimization opportunities
  # Provides metrics for:
  # - Query execution time
  # - N+1 query detection
  # - Missing index suggestions
  # - Cache effectiveness
  #
  # Usage:
  #   # Enable query tracking for a block
  #   QueryAnalyzer.track do
  #     @items = Item.includes(:stimulus, :indicator).all
  #   end
  #   # Prints: Query Report for 'Item batch load'
  #
  # Automatic Tracking (via Subscriber):
  #   # All queries logged automatically in development/test
  #   # Enabled via config/initializers/query_analyzer.rb

  # Track queries for a block of code
  def self.track(label = nil, &block)
    analyzer = new
    analyzer.record_queries(label, &block)
  end

  # Get current session statistics
  def self.stats
    Thread.current[:query_analyzer_stats] ||= {
      total_queries: 0,
      total_time: 0.0,
      queries: []
    }
  end

  # Reset statistics
  def self.reset_stats
    Thread.current[:query_analyzer_stats] = {
      total_queries: 0,
      total_time: 0.0,
      queries: []
    }
  end

  # Instance methods

  def initialize
    @queries = []
    @start_time = nil
  end

  def record_queries(label = nil, &block)
    @queries = []
    @start_time = Time.current

    # Subscribe to query events
    subscriber = subscribe_to_queries
    result = block.call
    unsubscribe_from_queries(subscriber)

    # Analyze and report
    analyze_and_report(label)
    result
  rescue => e
    unsubscribe_from_queries(subscriber) if subscriber
    raise
  end

  private

  def subscribe_to_queries
    ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      @queries << {
        sql: payload[:sql],
        binds: payload[:binds],
        name: payload[:name],
        duration: ((_finish - _start) * 1000).round(2) # Convert to ms
      }
    end
  end

  def unsubscribe_from_queries(subscriber)
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  def analyze_and_report(label)
    return if @queries.empty?

    elapsed = ((Time.current - @start_time) * 1000).round(2)
    query_count = @queries.count
    total_time = @queries.sum { |q| q[:duration] }

    report = {
      label: label || "Query Report",
      elapsed_ms: elapsed,
      query_count: query_count,
      total_query_time_ms: total_time,
      queries: @queries.take(20) # Show first 20 queries
    }

    log_report(report)
    detect_issues(report)
  end

  def log_report(report)
    Rails.logger.info <<~LOG

      ═══════════════════════════════════════════════════════════════════
      #{report[:label]}
      ═══════════════════════════════════════════════════════════════════
      Total Queries: #{report[:query_count]}
      Total Time:    #{report[:total_query_time_ms]}ms
      Elapsed:       #{report[:elapsed_ms]}ms
      ───────────────────────────────────────────────────────────────────
    LOG

    report[:queries].each_with_index do |query, idx|
      Rails.logger.info "[#{idx + 1}] #{query[:duration]}ms - #{query[:name]}"
      Rails.logger.debug "    #{query[:sql]}"
    end

    Rails.logger.info "═" * 67
  end

  def detect_issues(report)
    # Detect N+1 queries
    detect_n_plus_one(report[:queries])

    # Detect missing indexes (simplified heuristic)
    detect_slow_queries(report[:queries])

    # Detect duplicate queries
    detect_duplicate_queries(report[:queries])
  end

  def detect_n_plus_one(queries)
    # Find similar queries repeated multiple times
    query_patterns = queries.group_by { |q| normalize_query(q[:sql]) }

    query_patterns.each do |pattern, group|
      if group.size > 3 && pattern.include?("SELECT")
        Rails.logger.warn "[N+1 DETECTED] Query repeated #{group.size} times:"
        Rails.logger.warn "  #{pattern[0..100]}..."
      end
    end
  end

  def detect_slow_queries(queries)
    # Queries taking >50ms should be investigated
    queries.each do |query|
      if query[:duration] > 50
        Rails.logger.warn "[SLOW QUERY] #{query[:duration]}ms - #{query[:name]}"
        Rails.logger.warn "  #{query[:sql][0..150]}..."
      end
    end
  end

  def detect_duplicate_queries(queries)
    # Find exact duplicate queries
    query_map = {}
    queries.each do |query|
      key = query[:sql]
      query_map[key] ||= 0
      query_map[key] += 1
    end

    query_map.each do |sql, count|
      if count > 1
        Rails.logger.info "[DUPLICATE] Query executed #{count} times: #{sql[0..80]}..."
      end
    end
  end

  def normalize_query(sql)
    # Remove parameter values for pattern matching
    sql.gsub(/\d+/, "?").gsub(/'[^']*'/, "?")
  end
end
