##############################################
# Handy SQL queries for the original imdb db #
##############################################

# select movie info table
select * from movie_info

# Select movie id, title, rating and actors
SELECT t.id, title, info AS rating, p.name
FROM title AS t
INNER JOIN movie_info_idx AS i
ON t.id = i.movie_id
INNER JOIN cast_info AS ci
ON ci.movie_id = t.id
INNER JOIN name AS p
ON p.id = ci.person_id
WHERE t.kind_id = 1 # Movies
AND i.info_type_id = 101
AND ci.person_role_id = 1 # Actor
LIMIT 100


#Worldwide gross
SELECT title, cast(replace( substring(substring_index(m.info,' ',1),2), ",","") as unsigned) as yo, m.info
FROM title t
JOIN movie_info m ON m.movie_id = t.id
JOIN info_type ty ON m.info_type_id = ty.id
AND ty.info = 'gross'
AND m.info LIKE '$%Worldwide)' 
order by yo desc

# Alle produsert etter Ã¥r 2000 med minst 1000 stemmer
SELECT title, votes.info as votes, rating.info as rating, money.info as money FROM title
INNER JOIN movie_info_idx as votes
ON title.id = votes.movie_id
INNER JOIN movie_info_idx as rating
ON title.id = rating.movie_id
INNER JOIN movie_info as money
ON title.id = money.movie_id
WHERE title.kind_id = 1 # movie
AND title.production_year > 2000
AND votes.info_type_id = 100 # votes
AND rating.info_type_id = 101 # rating
AND money.info_type_id = 107 # money
AND votes.info > 1000


# Tittel, rating, votes, sjanger, språk, lanseringsdato, profit, plot
# Returnerer bare første sjanger når filmen har flere sjangere.
# Dette gjelder også språk, lanseringsdato, profit og plot.

SELECT t.id, t.title, t.production_year,
(SELECT info FROM movie_info_idx WHERE info_type_id = 101 AND movie_id = t.id) AS rating,
(SELECT info FROM movie_info_idx WHERE info_type_id = 100 AND movie_id = t.id) AS votes,
(SELECT info FROM movie_info WHERE info_type_id = 3 AND movie_id = t.id LIMIT 1) AS sjanger,
(SELECT info FROM movie_info WHERE info_type_id = 4 AND movie_id = t.id LIMIT 1) AS språk,
(SELECT info FROM movie_info WHERE info_type_id = 16 AND movie_id = t.id LIMIT 1) AS lanseringsdato,
(SELECT info FROM movie_info WHERE info_type_id = 107 AND movie_id = t.id LIMIT 1) AS profit,
(SELECT info FROM movie_info WHERE info_type_id = 98 AND movie_id = t.id LIMIT 1) AS plot
FROM title t
WHERE t.kind_id = 1 # Only movies
AND EXISTS (SELECT info FROM movie_info_idx WHERE info_type_id = 101 AND movie_id = t.id) # IMDB-rating exists


# Legge TOP 1000 ACTORS inn i mysql
CREATE TABLE top1000actors (
  position INT NOT NULL AUTO_INCREMENT,

 name VARCHAR(255) NOT NULL,
  PRIMARY KEY (position)
);



LOAD DATA LOCAL INFILE 'c:/top1000actors.csv'

INTO TABLE top1000actors
FIELDS TERMINATED BY ',' 
ENCLOSED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

