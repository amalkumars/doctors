require 'test_helper'
class EventTest < ActiveSupport::TestCase
  test "one simple test example" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:30")
    availabilities = Event.availabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 10), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 16), availabilities[6][:date]
    assert_equal 7, availabilities.length
  end

  test "multiple openings for a given day" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 10:30")
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 11:30"), ends_at: DateTime.parse("2014-08-04 12:30")
    availabilities = Event.availabilities DateTime.parse("2014-08-04")

    assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[0][:slots]
    assert_equal 7, availabilities.length
  end

  test "event dates cannot be blank" do
    event = Event.new kind: 'opening', starts_at: '', ends_at: nil
    assert_not event.valid?
    assert_equal [:starts_at, :ends_at], event.errors.keys
    assert_equal ["can't be blank", "is not a date"], event.errors.messages[:ends_at]
    assert_equal ["can't be blank"], event.errors.messages[:starts_at]
  end

  test "event ends_at cannot be less that starts_at" do
    event = Event.new kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 08:30")
    assert_not event.valid?
    assert_equal [:ends_at], event.errors.keys
    assert_equal ["must be after or equal to Mon, 04 Aug 2014 09:30:00 +0000"], event.errors.messages[:ends_at]
  end

  test "when no openings are found" do
    availabilities = Event.availabilities DateTime.parse("2014-08-15")
    assert_equal Date.new(2014, 8, 15), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]

    assert_equal Date.new(2014, 8, 16), availabilities[1][:date]
    assert_equal [], availabilities[1][:slots]

    assert_equal Date.new(2014, 8, 21), availabilities[6][:date]
    assert_equal [], availabilities[6][:slots]

    assert_equal 7, availabilities.length
  end

  test "recuring event is added on a future date but availability check date range doesn't fall under this" do
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30")
    Event.create kind: 'opening', starts_at: DateTime.parse("2017-05-01 07:00"), ends_at: DateTime.parse("2017-05-01 09:00"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-04 10:30"), ends_at: DateTime.parse("2014-08-04 11:30")
    availabilities = Event.availabilities DateTime.parse("2014-08-03")
    assert_equal Date.new(2014, 8, 3), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 4), availabilities[1][:date]
    assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 9), availabilities[6][:date]
    assert_equal 7, availabilities.length
  end
end
