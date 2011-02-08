module Admin::StatsHelper
  
  def moving_average(array, range)
    Array.new.tap do |arr|
      (0..(array.size - range)).each do |index|
        arr << array[index, range].mean
      end
    end
  end

end