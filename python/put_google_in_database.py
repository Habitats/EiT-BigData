import MySQLdb as mdb
import csv


"""
  This script inserts data from the given input file into the
  actors_starmeter_google table in the database
  NB! Does not delete old data

  CREATE TABLE `actors_starmeter_google` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `person_id` int(11) DEFAULT NULL,
    `starmeter_position` int(11) DEFAULT NULL,
    `google_results` int(11) DEFAULT NULL,
    `name` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"""

input_file = "google_and_starmeter_actor_rankings.csv"
actors = []

with open(input_file, 'r') as f:
  reader = csv.reader(f)
  next(reader) # Skip header row
  for row in reader:
    actors.append(row)
    
try:
  # Connect to database
  con = mdb.connect('localhost', 'root', 'bigeit', 'imdb_movies', use_unicode=True, charset='utf8')
  cur = con.cursor()

  for name, starmeter, google in actors:
    cur.execute("""INSERT INTO actors_starmeter_google (name, starmeter_position, google_results) 
     VALUES (%s, %s, %s)""", [name, starmeter, google])
    con.commit()

except mdb.Error, e:
  print "Error %d: %s" % (e.args[0], e.args[1])
  sys.exit(1)

finally:
  if con:
    con.close()
