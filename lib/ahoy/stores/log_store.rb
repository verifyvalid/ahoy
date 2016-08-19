module Ahoy
  module Stores
    class LogStore < BaseStore
      def track_visit(info, &block)
        data = {
          id: info[:visit_token],
          visitor_id: info[:visitor_token]
        }.merge(info.except(:visit_token, :visitor_token))
        data[:user_id] = user.id if user
        data[:started_at] = info[:time]

        yield(data) if block_given?

        log_visit(data)
      end

      def track_event(info, &block)
        data = {
          id: info[:event_token],
          name: info[:name],
          properties: info[:properties],
          visit_id: info[:visit_token],
          visitor_id: ahoy.visitor_id
        }
        data[:user_id] = user.id if user
        data[:time] = info[:time]

        yield(data) if block_given?

        log_event(data)
      end

      protected

      def log_visit(data)
        visit_logger.info data.to_json
      end

      def log_event(data)
        event_logger.info data.to_json
      end

      # TODO disable header
      def visit_logger
        @visit_logger ||= ActiveSupport::Logger.new(Rails.root.join("log/visits.log"))
      end

      def event_logger
        @event_logger ||= ActiveSupport::Logger.new(Rails.root.join("log/events.log"))
      end
    end
  end
end
