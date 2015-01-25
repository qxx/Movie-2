class MovieTest
  def initialize(data)
    @data = data
    @mean = cal_mean
  end

  def cal_mean
    sum = @data.inject(0) do |memo, hash|
      memo + hash[:prediction] - hash[:rating]
    end
    sum.to_f / @data.size
  end

  def mean
    @mean
  end

  def stddev
    sum = @data.inject(0) do |memo, hash|
      err = hash[:prediction] - hash[:rating]
      memo + (err - @mean) ** 2
    end
    return Math.sqrt(sum.to_f / (@data.size - 1))
  end

  def rms
    sum = @data.inject(0) do |memo, hash|
      memo + (hash[:prediction] - hash[:rating]) ** 2
    end
    return Math.sqrt(sum.to_f / @data.size)
  end

  def to_a
    array = []
    @data.each do |hash|
      array.push([hash[:user], hash[:movie], hash[:rating], hash[:prediction]])
    end
    return array
  end

end