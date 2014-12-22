# encoding: utf-8

class WorktimeEdit < Splitable

  self.incomplete_finish = false

  def add_worktime(worktime)
    if worktime.hours - remaining_hours > 0.00001    # we are working with floats: use delta
      worktime.errors.add(:hours, 'Die gesamte Anzahl Stunden kann nicht vergrössert werden')
    end
    worktime.employee = original.employee
    super(worktime) if worktime.errors.empty?
    worktime.errors.empty?
  end

  def page_title
    "Arbeitszeit von #{original.employee.label} bearbeiten"
  end

  def build_worktime
    empty? ? Ordertime.find(original_id) : Ordertime.new
  end

end
