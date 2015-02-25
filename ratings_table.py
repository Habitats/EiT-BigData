# -*- coding: utf-8 -*-
import MySQLdb as mdb
import time, sys, re
import util

# Runtime ~80 sec 

"""
CREATE TABLE `mpaa_ratings` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `movie_id` int(11) DEFAULT NULL,
  `rating` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"""
print "Running..."
try:
  # Connect to database
  con = mdb.connect('localhost', 'root', 'bigeit', 'imdb_movies', use_unicode=True, charset='utf8')
  cur = con.cursor()
  # One cursor for insertions
  cur2 = con.cursor()
  print "Connected to database"
  # Delete existing data
  cur2.execute("DELETE FROM mpaa_ratings")
  con.commit()
  print "Old data deleted"

  # Loop through all movies
  cur.execute("""
    SELECT movie_id, info FROM movie_info 
    WHERE info_type_id = 97
    """)
  print "Ratings loaded. Starting to insert values"

  data = cur.fetchone()
  while data:
    movie_id = data[0]
    raw_rating = data[1]

    rating = " ".join(raw_rating.split(" ")[0:2])

    # Insert data into budget table
    cur2.execute("""INSERT INTO mpaa_ratings (movie_id, rating) 
                   VALUES (%s, %s)""", [movie_id, rating])

    # Commit and get next row
    con.commit()
    data = cur.fetchone()

except mdb.Error, e:
    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

finally:
    if con:
        con.close()