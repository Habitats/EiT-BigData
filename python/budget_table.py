# -*- coding: utf-8 -*-
import MySQLdb as mdb
import time, sys, re
import util

# Runtime ~80 sec 

"""
CREATE TABLE `budget` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `movie_id` int(11) DEFAULT NULL,
  `budget` int(15) DEFAULT NULL,
  `currency` varchar(10) DEFAULT NULL,
  `usd_budget` int(15) DEFAULT NULL,
  `i_adj_usd_budget` int(15) DEFAULT NULL,
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
  cur2.execute("DELETE FROM budget")
  con.commit()
  print "Old data deleted"

  # Loop through all movies
  cur.execute("""
    SELECT movie_id, production_year, info FROM movie_info 
    INNER JOIN title ON title.id = movie_id 
    WHERE info_type_id = 105
    """)
  print "Movies loaded. Starting to insert values"

  # Pattern to match currency in string
  pattern = re.compile(r"([^0-9-\s]+)")

  data = cur.fetchone()
  i = 0
  while data:
    if i%10000==0:
      print i
    movie_id = data[0]
    production_year = data[1]
    raw_money = data[2]

    usd_budget = None

    currency = pattern.search(raw_money).groups()[0].encode("utf8")
    money = int(re.sub(r'[^\d.]', '', raw_money).replace(".",""))

    currency = util.normalizeCurrency(currency)
    usd_budget = util.convertToUsd(money, currency)

    infl_adj = None
    if production_year is not None and usd_budget is not None:
      infl_adj = usd_budget * 1.02947**(2015-production_year)

    # Insert data into budget table
    cur2.execute("""INSERT INTO budget (movie_id, budget, currency, usd_budget, i_adj_usd_budget) 
                   VALUES (%s, %s, %s, %s, %s)""", [movie_id, money, currency, usd_budget, infl_adj])

    # Commit and get next row
    con.commit()
    data = cur.fetchone()
    i += 1

  # Keep only the rows with the highest value
  cur2.execute("""DELETE FROM budget
                  WHERE id NOT IN (
                  SELECT id FROM (SELECT id, MAX(usd_budget) FROM budget GROUP BY currency, movie_id) as g2
              )""")
  con.commit()
  

except mdb.Error, e:
    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

finally:
    if con:
        con.close()
