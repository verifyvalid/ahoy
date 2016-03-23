module Ahoy
  class Tracker
    attr_reader :request, :controller

    def initialize(options = {})
      @store = Ahoy::Store.new(options.merge(ahoy: self))
      @controller = options[:controller]
      @request = options[:request] || @controller.try(:request)
      @options = options
    end

    def track(name, properties = {}, options = {})
      safely do
        if exclude?
          debug "Event excluded"
        else
          options = options.dup

          options[:time] = trusted_time(options[:time])
          options[:id] = ensure_uuid(options[:id] || generate_id)

          @store.track_event(name, properties, options)
        end
        true
      end
    end

    def track_visit(options = {})
      safely do
        if exclude?
          debug "Visit excluded"
        else
          if options[:defer]
            set_cookie("ahoy_track", true)
          else
            options = options.dup

            options[:started_at] ||= Time.zone.now

            @store.track_visit(options)
          end
        end
        true
      end
    end

    def authenticate(user)
      safely do
        if exclude?
          debug "Authentication excluded"
        else
          @store.authenticate(user)
        end
        true
      end
    end

    def visit
      @visit ||= @store.visit
    end

    def visit_token
      @visit_token ||= existing_visit_token || (api? && request.params["visit_token"]) || generate_token
    end

    def visitor_token
      @visitor_token ||= existing_visitor_token || (api? && request.params["visitor_token"]) || generate_token
    end

    def new_visit?
      !existing_visit_token
    end

    def new_visitor?
      !existing_visitor_token
    end

    def set_visit_cookie
      set_cookie("ahoy_visit", visit_token, Ahoy.visit_duration)
    end

    def set_visitor_cookie
      if new_visitor?
        set_cookie("ahoy_visitor", visitor_token, Ahoy.visitor_duration)
      end
    end

    def user
      @user ||= @store.user
    end

    # TODO better name
    def visit_properties
      @visit_properties ||= Ahoy::VisitProperties.new(request, @options.slice(:api))
    end

    # deprecated
    def visit_id
      @visit_id ||= ensure_uuid(existing_visit_token || visit_token)
    end

    # deprecated
    def visitor_id
      @visitor_id ||= ensure_uuid(existing_visitor_token || visitor_token)
    end

    protected

    def set_cookie(name, value, duration = nil)
      cookie = {
        value: value
      }
      cookie[:expires] = duration.from_now if duration
      domain = Ahoy.cookie_domain || Ahoy.domain
      cookie[:domain] = domain if domain
      request.cookie_jar[name] = cookie
    end

    def trusted_time(time)
      if !time || (@options[:api] && !(1.minute.ago..Time.now).cover?(time))
        Time.zone.now
      else
        time
      end
    end

    def exclude?
      @store.exclude?
    end

    def generate_token
      @store.generate_id
    end
    alias_method :generate_id, :generate_token

    def existing_visit_token
      @existing_visit_token ||= request && (request.headers["Ahoy-Visit"] || request.cookies["ahoy_visit"])
    end

    def existing_visitor_token
      @existing_visitor_token ||= request && (request.headers["Ahoy-Visitor"] || request.cookies["ahoy_visitor"])
    end

    def ensure_uuid(id)
      Ahoy.ensure_uuid(id)
    end

    def debug(message)
      Rails.logger.debug { "[ahoy] #{message}" }
    end

    def api?
      @options[:api]
    end
  end
end
