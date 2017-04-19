# Appointment Service
# This class handles all the Slot management
class SlotService
  # This method initailizes recurring_slots, non_recurring_slots, blocked_slots,
  # date and end_date for the slot service object for a given date
  def initialize(date)
    @recurring_slots = {}
    @non_recurring_slots = {}
    @blocked_slots = {}
    @date = date
    @end_date = date + 6.days
  end

  # This methods returns the available slots for next 7 days
  def available_slots
    events
    build_available_slots(@non_recurring_slots, @recurring_slots,
                          @blocked_slots)
  end

  private

  # This method finds different events and builds slots for each event
  def events
    recurring_events = Event.recurring.exclude_future_recurring_date(@date)
    non_recurring_events = Event.openings.by_date(@date)
    blocked_events = Event.appointments.by_date(@date)

    @non_recurring_slots = build_slots(non_recurring_events)
    @recurring_slots = build_slots(recurring_events)
    @blocked_slots = build_slots(blocked_events)
  end

  # This method returns the 7 days slots for given event type
  # E.g If event is of type recurring, blocked or non-recurring
  # => This method returns next 7 days slot for this event type
  def build_slots(events)
    slots = {}
    7.times { |i| slots[i] = [] }
    return slots if events.blank?
    events.each do |event|
      slots[event.starts_at.wday] << event.slots
      slots[event.starts_at.wday].flatten!
    end
    slots
  end

  # This method returns all the available slots for next 7 days
  # available slots for a date is found by
  # => adding non_recurring_slots and recurring_slots then
  # => subtracting blocked_slots
  def build_available_slots(non_recurring_slots, recurring_slots, blocked_slots)
    availability = []
    loop do
      week_day = @date.wday
      availability << {
        date:  @date.to_date,
        slots: non_recurring_slots[week_day] + recurring_slots[week_day] - blocked_slots[week_day]
      }
      break if (@date += 1.day) > @end_date
    end
    availability
  end
end
