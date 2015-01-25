require './MovieData.rb'

z = MovieData.new("ml-100k", :u1)

t = z.run_test(20)

puts "Mean = #{t.mean}"
puts "Std = #{t.stddev}"
puts "Rms = #{t.rms}"
p t.to_a.last
