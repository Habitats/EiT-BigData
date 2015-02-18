# -*- coding: utf-8 -*-
import MySQLdb as mdb
import time, sys, re

# Runtime ~80 sec 

"""
CREATE TABLE `gross` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `movie_id` int(11) DEFAULT NULL,
  `gross` int(11) DEFAULT NULL,
  `currency` varchar(10) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=344180 DEFAULT CHARSET=utf8;
"""

def normalizeDate(input):
  try:
    date = time.strptime(input, "%d %B %Y")
    return time.strftime("%Y-%m-%d", date)
  except ValueError:
    date = None

  if not date:
    try:
      date = time.strptime(input, "%Y")
      return time.strftime("%Y-%m-%d", date)
    except ValueError:
      return None

try:
  # Connect to database
  con = mdb.connect('bigdata.no-ip.org', 'root', 'bigeit', 'imdb_dev', use_unicode=True, charset='utf8')
  cur = con.cursor()
  # One cursor for insertions
  cur2 = con.cursor()

  # Loop through all movies
  cur.execute("SELECT movie_id, info FROM movie_info WHERE info_type_id = 107")

  # Pattern to match currency in string
  pattern = re.compile(r"([^0-9-\s]+)")

  data = cur.fetchone()
  while data:
    movie_id = data[0]
    value_string = data[1].replace(")", "").split("(")
    raw_money = value_string[0]
    location = value_string[1]

    date = None
    if len(value_string) > 2:
      date = normalizeDate(value_string[-1])

    currency = pattern.search(raw_money).groups()[0].encode("utf8")
    money = int(re.sub(r'[^\d.]', '', raw_money).replace(".",""))

    if currency == "£":
      currency = "GBP" 
    elif currency == "$":
      currency = "USD"
    elif currency == "€":
      currency = "EUR"

    # Insert data into gross table
    cur2.execute("""INSERT INTO gross (movie_id, gross, currency, date) 
                   VALUES (%s, %s, %s, %s)""", [movie_id, money, currency, date])

    # Commit and get next row
    con.commit()
    data = cur.fetchone()

except mdb.Error, e:
    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

finally:
    if con:
        con.close()
