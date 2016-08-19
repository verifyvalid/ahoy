module Ahoy
  module Stores
    class BaseStore
      def initialize(options)
        @options = options
      end

      def track_visit(info)
      end

      def track_event(info)
      end

      def visit
      end

      def authenticate(info)
        user = info[:user]
        @user = user
        if visit && visit.respond_to?(:user) && !visit.user
          begin
            visit.user = user
            visit.save!
          rescue ActiveRecord::AssociationTypeMismatch
            # do nothing
          end
        end
      end

      def user
        @user ||= (controller.respond_to?(:current_user) && controller.current_user) || (controller.respond_to?(:current_resource_owner, true) && controller.send(:current_resource_owner)) || nil
      end

      def exclude?
        bot?
      end

      def generate_id
        SecureRandom.uuid
      end

      protected

      def bot?
        @bot ||= request ? Browser.new(request.user_agent).bot? : false
      end

      def request
        @request ||= @options[:request] || controller.try(:request)
      end

      def controller
        @controller ||= @options[:controller]
      end

      def ahoy
        @ahoy ||= @options[:ahoy]
      end

      def set_visit_properties(visit, info)
        keys = info.keys
        keys.each do |key|
          visit.send(:"#{key}=", info[key]) if visit.respond_to?(:"#{key}=") && info[key]
        end
      end

      def geocode(visit)
        if Ahoy.geocode == :async
          Ahoy::GeocodeJob.set(queue: Ahoy.job_queue).perform_later(visit)
        end
      end

      def unique_exception_classes
        classes = []
        classes << ActiveRecord::RecordNotUnique if defined?(ActiveRecord::RecordNotUnique)
        classes << PG::UniqueViolation if defined?(PG::UniqueViolation)
        classes
      end
    end
  end
end
