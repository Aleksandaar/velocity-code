# Purpose:
#   Base implementation of calendar syncing strategy.
#   Define subclasses to implement customized strategies.

module GoogleCalendar::Sync
  class Strategy
    attr_reader :calendar, :data
    delegate :new_and_updated, to: :data
    delegate :deleted, to: :data

    def initialize (calendar)
      @calendar       = calendar
      @error_reporter = ErrorReporter.new(incremental?)
    end

    def incremental?
      true
    end

    def sync
      fetch_event_data
      update_current_events
      remove_cancelled_events
      update_last_synced_timestamps
    end

    def fetch_event_data
      @data = CalendarSyncDataSource.new(calendar).fetch(incremental?)
    end

    def update_last_synced_timestamps
      calendar.set_last_synced_at data.timestamp, incremental?
    end

    def update_current_events
      new_and_updated.each do |remote_event|
        create_or_update_local_event(remote_event)
      end
    end

    def remove_cancelled_events
      deleted.each do |remote_event|
        local_event = local_event_for_remote_event(remote_event)
        local_event.destroy unless local_event.nil?
      end
    end

    def create_or_update_local_event (remote_event)
      local_event           = find_or_create_local_event(remote_event)
      checked_for_conflicts = checked_for_conflicts?(local_event, remote_event)
      attributes            = local_event_attributes(remote_event, checked_for_conflicts)
      local_event.update_attributes!(attributes)
      @error_reporter.report_syncing_errors(remote_event, @calendar)
    end

    def local_event_attributes (remote_event, checked_for_conflicts)
      {
         start_time:              remote_event.start_time,
         end_time:                remote_event.end_time,
         title:                   remote_event.title,
         details:                 remote_event.details,
         url:                     remote_event.url,
         remote_event_updated_at: remote_event.updated_at,
         checked_for_conflicts:   checked_for_conflicts
      }
    end

    def find_or_create_local_event (remote_event)
      local_event = local_event_for_remote_event(remote_event) ||
         CalendarEvent.new({
            calendar:          calendar,
            event_id:          remote_event.id,
            event_instance_id: remote_event.instance_id
         })
    end

    def local_event_for_remote_event (remote_event)
      CalendarEvent.where(event_id: remote_event.id, calendar_id: calendar.id).first
    end

    def checked_for_conflicts?(local_event, remote_event)
      local_event.checked_for_conflicts && time_unchanged?(local_event, remote_event)
    end

    def time_unchanged?(local_event, remote_event)
      local_event.start_time == remote_event.start_time && local_event.end_time == remote_event.end_time
    end

  end
end