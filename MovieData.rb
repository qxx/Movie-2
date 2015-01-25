require './MovieTest.rb'

class MovieData
  def initialize(dir, user = nil)

    if user.nil?
      training_filename = dir + '/u.data'
    else
      training_filename = dir + '/' + user.to_s + '.base'
      test_filename = dir + '/' + user.to_s + '.test'
    end
    training_file = open(training_filename)
    test_file = open(test_filename) unless test_filename.nil?

    @training_data = load_data(training_file)
    @test_data = load_data(test_file)
    @training_ratings_u = prioritize(@training_data, 'user')
    @training_ratings_m = prioritize(@training_data, 'movie')
  end

  attr_accessor :distance_type
  
  def load_data(file)
    return nil if file.nil?
    data_array = []
    file.each_line do |line|
      one_line = line.chomp.split(/\t/)
      line_hash = Hash.new
      line_hash[:user_id] = one_line[0].to_i
      line_hash[:movie_id] = one_line[1].to_i
      line_hash[:rating] = one_line[2].to_i
      line_hash[:timestamp] = one_line[3].to_i

      data_array.push(line_hash)
    end
    return data_array
  end

  def prioritize(data, priority_key)
    return nil if data.size == 0
    scores = Hash.new
    data.each do |line|
      uid = line[:user_id]
      mid = line[:movie_id]
      rating = line[:rating]

      if priority_key == 'user'
        set_priority(scores, uid, mid, rating)
      else
        set_priority(scores, mid, uid, rating)
      end
    end
    return scores
  end

  def set_priority(scores, key1, key2, rating)
    if scores[key1].nil?
      scores[key1] = {key2 => rating}
    else
      scores[key1][key2] = rating
    end
  end

  def movie_prioritize(ratings)
    new_ratings = Hash.new
    ratings.each do |uid, m_pair|
      m_pair.each do |mid, rating|
        if new_ratings[mid].nil?
          new_ratings[mid] = {uid => rating}
        else
          new_ratings[mid][uid] = rating
        end
      end
    end
    return new_ratings
  end

  def rating(u, m)
    rating = @training_ratings_u[u][m]
    return rating.nil? ? 0 : rating
  end
  
  def distance(x, y, distance_type)
    distance_type = 1.0 if distance_type.nil?
    return (x - y).abs ** distance_type
  end

  # Adapted from pearson gem
  def shared_items(scores, entity1, entity2)
    Hash[*(scores[entity1].keys & scores[entity2].keys).flat_map{|k| [k, 1]}]
  end

  def similarity(scores, user1, user2)
    shared_items = shared_items(scores, user1, user2)
    n = shared_items.length
    return 1 if n==0
    sum = 0
    
    shared_items.each_key do |mid|     
      sum += distance(scores[user1][mid], scores[user2][mid], @distance_type)
    end

    return sum == 0 ? 0 : -sum.to_f / n
  end

  def most_similar(scores, u)
    first_pair = (u == 1 ? 2 : 1)
    max_similarity = similarity(scores, u, first_pair)
    user_list = {first_pair => max_similarity}

    (1..scores.length).each do |uid|
      next if uid == u && uid == first_pair
      this_similarity = similarity(scores, u, uid)
      next if this_similarity < max_similarity || this_similarity == 1
      
      if this_similarity > max_similarity
         # only save the **most** similar ones
         user_list.clear
         max_similarity = this_similarity
      end
      
      user_list[uid] = this_similarity
    end

    return user_list
  end

  def predict(u, m)
    users = most_similar(@training_ratings_u, u).keys
    ratings = []
    users.each {|uid| ratings.push(@training_ratings_u[uid][m])}
    ratings.compact!
    if ratings.size == 0
      return average_rating(m).round(2)
    else
      return (ratings.reduce(:+).to_f / ratings.size).round(2)
    end
  end

  def average_rating(m)
    # Very rare case that the movie did not appear in the training data
    return 3.0 if @training_ratings_m[m].nil?
    ratings = @training_ratings_m[m].values
    ratings.reduce(:+).to_f / ratings.size
  end

  def movies(u)
    @training_ratings_u[u].keys
  end

  def viewers(m)
    @training_ratings_m[m].keys
  end

  def run_test(k = nil)
    exit(1) if @test_data.nil?
    k = @test_data.size if k.nil?
    puts k
    result = []
    (0...k).each do |i|
      uid = @test_data[i][:user_id]
      mid = @test_data[i][:movie_id]
      rating = @test_data[i][:rating]
      puts "uid not found" if uid.nil?
      puts "mid not found" if mid.nil?
      puts "rating not found" if rating.nil?
      prediction = predict(@test_data[i][:user_id], @test_data[i][:movie_id])
      result[i] = {user: uid, movie: mid, rating: rating, prediction: prediction}
      puts i
    end
    return MovieTest.new(result)
  end
end