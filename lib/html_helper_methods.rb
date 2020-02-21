helpers do
  # Returns string depending on how many plants user has
  def num_of_plants
    return " has no plants at the moment." if @plants.empty?

    " is currently caring for #{plural_count(@plants.size, 'plant')}."
  end

  # Returns string depending on how many plants current user has
  def user_num_of_plants
    return "You have no plants, start growing your family now!" if @plants.empty?

    if @plants.size == 1
      "You have 1 plant. It needs a friend!"
    else
      "You're currently caring for #{@plants.size} plants"
    end
  end

  # Returns boolean if user is viewing their own page
  def current_user
    @username == session[:username]
  end

  # Returns an integer count of times watered this week
  def watering_count(plant)
    current_week = Date.today.cweek
    plant['last_water'].count { |date| date.cweek == current_week }
  end

  # Returns the count and number, with an 's' appended if plural.
  def plural_count(number, word)
    classifier = number.to_i == 1 ? word : word + 's'
    number.to_s + ' ' + classifier
  end

  # Returns the last date water String formatted as (Feb 15)
  def last_water_date(plant)
    plant['last_water'].max.strftime("%b %d")
  end

  def state_of_plant(plant)
    watering_count(plant) >= plant['schedule'].to_i ? 'finished' : 'unfinished'
  end
end
