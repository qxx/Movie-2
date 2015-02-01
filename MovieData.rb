require './MovieTest.rb'

class MovieData
  
  # Create MovieData instance with data file given in "dir".
  # If "user", e.g. "u1", is given,  will read "u1.base" as the training set,
  # and "u1.test" will be the test set.
  # If "user" is not given, will read "u.data" as the training set,
  # and will have an empty test set.
  def initialize(dir, user = nil)
    training_file, test_file = get_file(dir, user)

    @training_data = load_data(training_file)
    @test_data = load_data(test_file)
    @training_ratings_u = prioritize(@training_data, 'user')
    @training_ratings_m = prioritize(@training_data, 'movie')
    # cache the similarity and similar user list
    @similarity_cache = Hash.new
    @similar_list_cache = Hash.new
    @average_rating_cache = Hash.new
  end

  # Change the distance parameter in the similarity algrithm with this accessor.
  attr_accessor :distance_type

  # Return the rating that user u gave movie m in the training set
  # and 0 if user u did not rate movie m
  #
  # @param [Integer] User id
  # @param [Integer] Movie id
  #
  # @return [Integer] Rating
  def rating(u, m)
    rating = @training_ratings_u[u][m]
    return rating.nil? ? 0 : rating
  end
  
  # Return the estimated rating of movie m that user u may gave
  #
  # @param [Integer] User id
  # @param [Integer] Movie id
  #
  # @return [Float] Rating estimate 
  def predict(u, m)
    users = get_similar_users(@training_ratings_u, u)
    ratings = []
    users.each {|uid| ratings.push(@training_ratings_u[uid][m])}
    ratings.compact!

    if ratings.size == 0
      return average_rating(m).round(2)
    else
      return (ratings.reduce(:+).to_f / ratings.size).round(2)
    end
    
  end

  # Return the array of movies that user u has watched
  #
  # @param [Integer] User id
  #
  # @return [Array] Movies watched
  def movies(u)
    @training_ratings_u[u].keys
  end

  # Return the array of users that have seen movie m
  # 
  # @param [Integer] Movie id
  #
  # @return [Array] Users that have watched the movie
  def viewers(m)
    @training_ratings_m[m].keys
  end

  # Run the predict method on the first k ratings in the test set,
  # if k is omitted, all tests will be run.
  # In the returned MovieTest Object, data will be stored as
  # e.g. [{user:xxx, movie:yyy, rating:zzz, prediction:ppp}, ...]
  #
  # @param [Integer]
  #
  # @return [MovieTest] 
  def run_test(k = nil)
    exit(1) if @test_data.nil?
    k = @test_data.size if k.nil?

    result = []
    (0...k).each do |i|
      uid = @test_data[i][:user_id]
      mid = @test_data[i][:movie_id]
      rating = @test_data[i][:rating]
      prediction = predict(uid, mid)
      result[i] = {user: uid, movie: mid, rating: rating, prediction: prediction}
    end

    return MovieTest.new(result)
  end

  private
  ## Part 1 load data

  # Put together the filenames and open the files
  def get_file(dir, user)
    if user.nil?
      training_filename = './'+dir + '/u.data'
    else
      training_filename = './'+dir + '/' + user.to_s + '.base'
      test_filename = './'+dir + '/' + user.to_s + '.test'
    end
    training_file = open(training_filename)
    test_file = open(test_filename) unless test_filename.nil?
    return training_file, test_file
  end

  # Read the data file line by line, store each line in a hash,
  # finally return an array of hashes. 
  # 
  # param [file]
  #
  # return [Array] e.g. [{user_id:xxx, movie_id:yyy, rating:zzz, timestamp:ttt}, ...]
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

  # Organize the data read from load_data in the form decided by priority_key,
  # returns a hash of hashes
  # 
  # e.g. given priority_key is "user", the returned hash will be like:
  # {uid => {mid => rating, mid => rating, ...}, uid => {...}, ...}
  #
  # @param [Array]
  # @param [String] either "user" or "movie"
  #
  # @return [Hash]
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
  
  # Store the given rating in the stucture order given by key1, key2
  #
  # @param [Hash]
  # @param [Integer]
  # @param [Integer]
  # @param [Integer]
  def set_priority(scores, key1, key2, rating)
    scores[key1] = Hash.new unless scores.has_key?(key1)
    scores[key1][key2] = rating
  end

  ## Part 2 calculate similarity

  # Calculate the distance between the two ratings
  #
  # @param [Integer] rating
  # @param [Integer] rating
  # @param [Float] power of |x-y|, default 1.0
  #
  # @return [Float] distace
  def distance(x, y, distance_type)
    distance_type = 1.0 if distance_type.nil?
    return (x - y).abs ** distance_type
  end

  # Adapted from pearson gem
  # Returns a hash containing the shared items between two different entities
  def shared_items(scores, entity1, entity2)
    Hash[*(scores[entity1].keys & scores[entity2].keys).flat_map{|k| [k, 1]}]
  end

  # Read the similarity of two users from cache, calculate if not found
  #
  # @param [Hash] Hash containing ratings
  # @param [Integer] User id
  # @param [Integer] User id
  #
  # @return [Float] Similarity
  def similarity(scores, user1, user2)
    u1, u2 = [user1, user2].sort
    @similarity_cache[u1] = Hash.new unless @similarity_cache.has_key?(u1)
    @similarity_cache[u1][u2] = cal_similarity(scores, u1, u2) unless @similarity_cache[u1].has_key?(u2)
    return @similarity_cache[u1][u2]
  end

  # Calculate the simialarity of two users
  # Larger the similiarity is, more similiar the users are.
  #
  # @param [Hash] Hash containing ratings
  # @param [Integer] User id
  # @param [Integer] User id
  #
  # @return [Float] Similiarity
  def cal_similarity(scores, user1, user2)
    shared_items = shared_items(scores, user1, user2)
    n = shared_items.length
    return 1 if n==0
    sum = 0
    
    shared_items.each_key do |mid|     
      sum += distance(scores[user1][mid], scores[user2][mid], @distance_type)
    end

    return sum == 0 ? 0 : -sum.to_f / n
  end

  ## Part 3 get most similar list and do prediction
  
  # Check the cached list, and call most_similar to generate the list if necessary
  #
  # @param [Hash] Hash containing ratings
  # @param [Integer] User id
  #
  # @return [Array] The list of most similar users
  def get_similar_users(scores, u)
    @similar_list_cache[u] = most_similar(scores, u) unless @similar_list_cache.has_key?(u)
    return @similar_list_cache[u]
  end

  # Return a list of users that are most similiar to the user given
  #
  # @param [Hash] Hash containing cached most-similar-user lists
  # @param [Hash] Hash containing ratings
  # @param [Integer] User id
  #
  # @return [Array] Most similar users
  def most_similar(scores, u)
    first_pair = (u == 1 ? 2 : 1)
    max_similarity = similarity(scores, u, first_pair)
    user_list = {first_pair => max_similarity}

    scores.each do |uid, rating|
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
    
    return user_list.keys
  end
  
  # Look up the average rating from cache, and calculate it if not found
  #
  # @param [Integer] Movie id
  #
  # @return [Float average rating]
  def average_rating(m)
    @average_rating_cache[m] = cal_average_rating(m) unless @average_rating_cache.has_key?(m)
    return @average_rating_cache[m]
  end

  # Return the average rating of all ratings of movie m
  # 
  # @param [Integer] Movie id
  # 
  # @return [Float] average rating
  def cal_average_rating(m)
    # Very rare case that the movie did not appear in the training data
    return 3.0 if @training_ratings_m[m].nil?
    ratings = @training_ratings_m[m].values
    ratings.reduce(:+).to_f / ratings.size
  end

end