# Event Model
# Assumptions Made
# => Event will have start and end date in the same day
# => Multiple opening entries is possible in a day E.g [9 - 10:30], [12 - 3:30]
# => Appointment is created only on available slots
# => Each slot is of a 30 min duration
class Event < ActiveRecord::Base
  scope :recurring, -> { where(weekly_recurring: true) }
  scope :openings, -> { where(kind: 'opening') }
  scope :appointments, -> { where(kind: 'appointment') }

  # To add validations
  # => starts_at and ends_at cannot be blank
  # => ends_at should always be greater that or equal to starts_at
  validates :starts_at, presence: true
  validates :ends_at, presence: true, date: { after_or_equal_to:  :starts_at }

  class << self
    # This method returns all the available slots for the next 7 days from the
    # given date.
    def availabilities(date)
      service = SlotService.new(date)
      service.available_slots
    end

    # This method is used to query records in a date range of 7 days
    def by_date(date)
      where('starts_at >= ? and starts_at < ?', date, date + 7.days)
    end

    # This is to handle the scenario
    # => Recurring event starts_at May 1, 2017 (monday) 9:00 - 12:00
    # => This means mondays that come after May 1 have event open at 9 - 12
    # But for all mondays that comes before May 1 shouldn't be considered
    def exclude_future_recurring_date(date)
      where('starts_at < ?', date + 7.days)
    end
  end

  # This method returns the time slot array for a given event
  # E.g. if an event has starts_at: 2014-08-04 09:30:00 and
  #         ends_at: 2014-08-04 12:30:00
  # Output: ['9:30', '10.00', '10:30', '11:00', '11:30', '12:00', '12:30']
  def slots
    start_time = starts_at
    slot_array = []
    loop do
      slot_array << start_time.strftime('%-k:%M')
      break if (start_time += 1800) >= ends_at
    end
    slot_array
  end
end
