# Movie-2

CodeClimate report
------------------
[https://codeclimate.com/repos/54c5526869568051e5002730/](https://codeclimate.com/repos/54c5526869568051e5002730/)

GitHub Repo
------------------
[https://github.com/qxx/Movie-2](https://github.com/qxx/Movie-2)

Algorithm
------------------
### Similarity 
I define the similarity of two users as -Avg(|r1-r2|^d), where r1 and r2 are the ratings of each shared movie by user1 and user2, and d is the distance type which is default to be 1.0. Therefore the most similar ones should have a similarity of 0. 

If the two users don't have any shared movies, 1 is returned as an error code.

### Most Similar List
Only the users that have the largest and exact same similarity with the user to test are stored in the user list, which could be one, or could be a dozen.

### Prediction
Look up the ratings of this movie in this user's most similar list, ignore those who haven't rated this movie, and finially return the average of these ratings.

If no one in the most similar list has rated the movie, then the average of all ratings of this movie in the training set is returned.

In some extreme cases, this movie does not have even one rating in the training set, then 3.0 is returned. 

### Pros and Cons
With the assumption that two similar persons are more likely to rate close, this algorithm should work better than just returning the average of all ratings.

However, the way to determine "most similar users" is still rough. I did not consider the possiblity that some users may be more "valuable" than others, and also the possiblity that two users happen to be similiar in the eyes of this algorithm but in fact they are not. 

Analysis
------------------
The tests are done within the test.rb file. 
* 100 tests: Mean: -0.167, Std: 1.020, RMS: 1.028
* 1000 tests: Mean: -0.036, Std: 1.103, RMS: 1.103
* 10000 tests: Mean: 0.038, Std: 1.135, RMS: 1.136
* all u1 tests: Mean: 0.0056, Std: 1.108, RMS: 1.108
* all u2 tests: Mean: 0.0056, Std: 1.087, RMS: 1.087
* all u3 tests: Mean: 0.0233, Std: 1.089, RMS: 1.089
* all u4 tests: Mean: 0.0260, Std: 1.083, RMS: 1.084
* all u5 tests: Mean: 0.0322, Std: 1.089, RMS: 1.090

The Mean is close to 0, which shows the algorithm did go in the right direction. An almost-zero mean also means the Stderr and RMS would be close.

The Stderr and RMS are a little larger than 1.0, which means the prediction is likely to have an +/-1 error. This is not very accurate, but still should be able to tell the general idea whether the user likes or dislikes a certain movie.  


Benchmarking
------------------
The exact running time depends much on the hardware. I use the "time" shell command to capture the running time on my 6-year-old linux computer. After adding caching to the program, the performance has been improved.
* ~~Was 9s~~ Now 1.3s for first 100 tests
* ~~Was 1m25s~~ Now 2.1s for first 1000 tests
* ~~Was 11m36s~~ Now 14.0s for first 10000 tests

Some more tests:
* all u1 tests: 26.2s
* all u2 tests: 32.0s
* all u3 tests: 34.5s
* all u4 tests: 33.7s
* all u5 tests: 33.7s

I orgnized the training data in two hashes: {uid=>{mid=>rating, ..}, ..} and {mid=>{uid=>rating, ..} ..} so it will only cost minimal time to look up the ratings of a certain movie, or of a certain person.

Also I cached the results of the calculated similarity of two users, and the most similar user list, which improved the preformance dramatically.

Finally I cached the average of all user ratings for a certain movie, which is not often used, but it still saves about 2.5% time.

Let m be the size of training set, and n be the size of the test set, the time complexity should be the sum of:
* O(m+n) to load the files
* O(2m) to orangize the data
* ~~O(m)*O(n)~~ O(n) to find the most similar list for all test users
* O(l)*O(n) to calculate the average rating, where l is length of the most similar list, which should be ~O(1)

So the overall time should be around O(m+n)