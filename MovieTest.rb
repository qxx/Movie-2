class MovieTest
  # Store the data and calculate the mean error
  def initialize(data)
    @data = data
    @mean = cal_mean
  end

  # Return the mean error
  #
  # return [Float]
  def mean
    @mean
  end

  # Return the standard deviation of the error
  #
  # return [Float]
  def stddev
    sum = @data.inject(0) do |memo, hash|
      err = hash[:prediction] - hash[:rating]
      memo + (err - @mean) ** 2
    end
    return Math.sqrt(sum.to_f / (@data.size - 1))
  end

  # Return the root ean square error of the prediction
  #
  # return [Float]
  def rms
    sum = @data.inject(0) do |memo, hash|
      memo + (hash[:prediction] - hash[:rating]) ** 2
    end
    return Math.sqrt(sum.to_f / @data.size)
  end

  # Return an array of predictions in the form [u,m,r,p]
  #
  # return [Array]
  def to_a
    array = []
    @data.each do |hash|
      array.push([hash[:user], hash[:movie], hash[:rating], hash[:prediction]])
    end
    return array
  end

  private

  # Calculate the mean error
  #
  # return [Float]
  def cal_mean
    sum = @data.inject(0) do |memo, hash|
      memo + hash[:prediction] - hash[:rating]
    end
    sum.to_f / @data.size
  end

end