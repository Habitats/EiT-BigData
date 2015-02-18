#!/usr/bin/python
import MySQLdb
import unirest


def fetchFromDb():
    global db, cur, row
    db = MySQLdb.connect(host="bigdata.no-ip.org",
                         user="root",
                         passwd="bigeit",
                         db="imdb_dev")
    cur = db.cursor()
    # Use all the SQL you like
    cur.execute(
        """
    SELECT t.id, t.title, GROUP_CONCAT(kw.keyword SEPARATOR ',') AS keywords
    FROM title t
    JOIN movie_keyword k ON t.id = k.movie_id
    JOIN keyword kw ON kw.id = k.keyword_id
    GROUP BY t.id
    LIMIT 10
         """)

    res = cur.fetchall()

    pairs = []
    for r in res:
        pairs.append([r[1], r[2]])

    return pairs


def fetchFromApi(pairs):
    res = []
    for p in pairs:
        response = unirest.post("https://japerk-text-processing.p.mashape.com/sentiment/",
                                headers={
                                    "X-Mashape-Key": "1YFj02jNXOmshrqfic9OLvQB9NZSp1VU8XxjsnoqDhG0M7lrSo",
                                    "Content-Type": "application/x-www-form-urlencoded",
                                    "Accept": "application/json"
                                },
                                params={
                                    "language": "english",
                                    "text": p[1]
                                }
        )
        res.append([p[0], response._body])
    return res

pairs = fetchFromDb()
res = fetchFromApi(pairs)

for r in res:
    print r
