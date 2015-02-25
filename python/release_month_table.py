# -*- coding: utf-8 -*-
import MySQLdb as mdb
import time, sys, re
import util

# Runtime ~80 sec 

"""
CREATE TABLE `release_month` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `movie_id` int(11) DEFAULT NULL,
  `release_month` int(11) DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"""
print "Running..."
try:
  # Connect to database
  con = mdb.connect('localhost', 'bigeit', 'bigeit', 'imdb', use_unicode=True, charset='utf8')
  cur = con.cursor()
  # One cursor for insertions
  cur2 = con.cursor()
  print "Connected to database"
  # Delete existing data
  cur2.execute("DELETE FROM release_month")
  con.commit()
  print "Old data deleted"

  # Loop through all movies
  cur.execute("""
    SELECT movie_id, info FROM movie_info 
    WHERE info_type_id = 16
    """)
  print "Ratings loaded. Starting to insert values"

  data = cur.fetchone()
  while data:
    movie_id = data[0]
    raw_date = data[1]
    month = None
    year = None
    try:
      date = time.strptime(raw_date.split(":")[1], "%d %B %Y")
      month = date.tm_mon
      year = date.tm_year
    except:
      pass

    # Insert data into budget table
    cur2.execute("""INSERT INTO release_month (movie_id, release_month, year) 
                   VALUES (%s, %s, %s)""", [movie_id, month, year])

    # Commit and get next row
    con.commit()
    data = cur.fetchone()

except mdb.Error, e:
    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

finally:
    if con:
        con.close()