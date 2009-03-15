class Date
  def distance_to(end_date)
    years = end_date.year - year
    months = end_date.month - month
    days = end_date.day - day
    if days < 0
      days += 30
      months -= 1
    end
    if months < 0
      months += 12
      years -= 1
    end
    {:years => years, :months => months, :days => days}
  end
end
