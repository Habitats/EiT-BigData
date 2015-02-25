# -*- coding: utf-8 -*-
import MySQLdb as mdb
import time, sys, re
import util

# Runtime ~80 sec 

"""
CREATE TABLE `gross` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `movie_id` int(11) unsigned DEFAULT NULL,
  `gross` bigint(15) DEFAULT NULL,
  `currency` varchar(10) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `usd_gross` bigint(15) DEFAULT NULL,
  `i_adj_usd_gross` bigint(15) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"""

try:
    # Connect to database
    con = mdb.connect('localhost', 'root', 'bigeit', 'imdb_movies', use_unicode=True, charset='utf8')
    # con = mdb.connect('localhost', 'bigeit', 'bigeit', 'imdb', use_unicode=True, charset='utf8')
    cur = con.cursor()
    # One cursor for insertions
    cur2 = con.cursor()
    print "Database connection established"

    # Delete existing data
    cur2.execute("DELETE FROM gross")
    con.commit()
    print "Old data deleted"

    # Loop through all movies
    cur.execute("SELECT movie_id, info FROM movie_info WHERE info_type_id = 107")

    print "Movies loaded"

    # Pattern to match currency in string
    pattern = re.compile(r"([^0-9-\s]+)")

    data = cur.fetchone()
    i = 0
    while data:
        if i % 10000 == 0:
            print ".",
        i += 1
        movie_id = data[0]
        value_string = data[1].replace(")", "").split("(")
        raw_money = value_string[0]
        location = value_string[1]

        date = None
        year = None
        usd_gross = None

        if len(value_string) > 2:
            date = util.normalizeDate(value_string[-1])
        if date:
            year = int(date[0:4])

        currency = pattern.search(raw_money).groups()[0].encode("utf8")
        money = int(re.sub(r'[^\d.]', '', raw_money).replace(".", ""))

        currency = util.normalizeCurrency(currency)
        usd_gross = util.convertToUsd(money, currency)

        infl_adj = None
        if year is not None and usd_gross is not None:
            infl_adj = usd_gross * 1.02947 ** (2015 - year)

        try:
            # Insert data into gross table
            cur2.execute("""INSERT INTO gross (movie_id, gross, currency, date, usd_gross, i_adj_usd_gross)
                   VALUES (%s, %s, %s, %s, %s, %s)""", [movie_id, money, currency, date, usd_gross, infl_adj])

            # Commit and get next row
            con.commit()
        except:
            pass

        data = cur.fetchone()

    # Keep only the rows with the highest value
    cur2.execute("""DELETE FROM gross
                  WHERE id NOT IN (
                  SELECT id FROM (SELECT id, MAX(usd_gross) FROM gross GROUP BY currency, movie_id) as g2
              )""")
    con.commit()

except mdb.Error, e:
    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

finally:
    if con:
        con.close()
