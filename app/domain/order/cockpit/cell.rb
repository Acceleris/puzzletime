class Order::Cockpit
  class Cell < Struct.new(:hours, :amount)

    def days
      hours / must_hours_per_day if hours
    end

    def must_hours_per_day
      WorkingCondition.todays_value(:must_hours_per_day)
    end

  end
end
