##############################################
# Handy SQL queries for the original imdb db #
##############################################

# Select movie info table
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

# Worldwide gross
SELECT title, max(cast(replace( substring(substring_index(m.info,' ',1),2), ",","") as unsigned)) as gross
FROM title t
JOIN movie_info m ON m.movie_id = t.id
JOIN info_type ty ON m.info_type_id = ty.id
AND ty.info = 'gross'
group by title
order by gross desc
limit 1000

# Alle produsert etter år 2000 med minst 1000 stemmer
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

# Fjerner tom rad på alle skuespillernavn
UPDATE top1000actors SET name=replace(replace(name, '\n', ''),'\r', '')


# Legger til skuespiller-score i top1000actors-tabellen
ALTER TABLE top1000actors 
ADD score INT NOT NULL;
UPDATE top1000actors SET score = ((1000-position) DIV 100) +1 WHERE position BETWEEN 1 AND 1000;


# Total skuespiller-score på alle filmer produsert etter år 2000 med 100 votes
# Tar 2 minutter på LIMIT 10....

SELECT t.id, t.title, t.production_year, rating.info AS imdbScore, votes.info AS votes, SUM(top.score) AS TotalActorScore
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN name n ON ci.person_id = n.id
JOIN top1000actors top ON top.name = n.name 
JOIN movie_info_idx votes ON t.id = votes.movie_id
JOIN movie_info_idx rating ON t.id = rating.movie_id
WHERE ci.role_id BETWEEN 1 AND 2 # Actor or Actress
AND t.kind_id = 1 # Movie
AND votes.info_type_id = 100 # votes
AND rating.info_type_id = 101 # imdb-score
AND votes.info > 1000
AND t.production_year > 2000
GROUP BY t.id


# Legg til ny navn-kolonne i name-tabellen
ALTER TABLE name
ADD name2 text NOT NULL;
# Legg inn navn på format "Fornavn Etternavn" i denne nye kolonnen
UPDATE name SET name2 = concat(trim(substring_index(name, ",",-1))," " ,trim(substring_index(name, ",",1))) WHERE id BETWEEN 0 AND 4993554


#View for model1

CREATE VIEW model1
AS (
SELECT t.id AS ID, t.title AS Title, l.language AS Language,
GROUP_CONCAT(g.genres SEPARATOR ',') AS Genres, r.runtime AS Runtime,mpaa.mpaa AS MPAA,
rm.release_month AS ReleaseMonth, IFNULL(top.logscore,0) AS TotalActorLogScore,
IFNULL(top2.logscore,0) AS TotalDirectorLogScore, v.votes AS Votes, ra.rating AS Rating,
ra.rating_cat AS IntegerRating, ra.rating_enum AS RatingCategory, bu.usd_budget AS UsdBudget,
bu.i_adj_usd_budget AS UsdAdjBudget, gr.usd_gross AS UsdGross, gr.i_adj_usd_gross AS UsdAdjGross,
AVG(gs.avg_rating) AS GenreRating
FROM title t
JOIN language l ON t.id = l.movie_id
JOIN genres g ON t.id = g.movie_id
JOIN runtimes r ON t.id = r.movie_id
JOIN mpaa_ratings mpaa ON t.id = mpaa.movie_id
JOIN release_month rm ON t.id = rm.movie_id
LEFT JOIN actor_scores top ON top.movie_id = t.id 
LEFT JOIN director_scores top2 ON top2.movie_id = t.id 
JOIN votes v ON t.id = v.movie_id
JOIN rating ra ON t.id = ra.movie_id
JOIN budget bu ON t.id = bu.movie_id
JOIN gross gr ON t.id = gr.movie_id
JOIN genre_score gs ON g.genres = gs.genre
GROUP BY t.id);

# Fjern land fra runtime-tabellen, deretter normalisering av data
UPDATE runtimes
SET runtime = SUBSTRING_INDEX(runtime, ':', -1)
UPDATE runtimes
SET runtime = 
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(
	SUBSTRING_INDEX(REPLACE(runtime, ' ', ''), 'm', 1), 
	's', 1),
	'\'', 1),
	'/', 1),
	',',1),
	'.',1),
	';',1),
	'-',1),
	'"',1),
	'x',1),
	'+',1),
	'*',1);
UPDATE runtimes 
SET runtime = NULL
where runtime = ' ';


# Opprette runtimes-tabellen

CREATE TABLE runtimes (
   id int(11) unsigned NOT NULL AUTO_INCREMENT,
   movie_id int(11) DEFAULT NULL,
   runtime text DEFAULT NULL,
   PRIMARY KEY (id),
   CONSTRAINT runtime_movie_id_fk FOREIGN KEY (movie_id) REFERENCES title (id) ON DELETE CASCADE
 ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
 
SET @rank=0;
INSERT INTO runtimes(
SELECT @rank:=@rank+1 AS rank, t.id AS movie_id, runtime.info AS runtime
FROM title t
JOIN movie_info runtime ON t.id = runtime.movie_id
WHERE runtime.info_type_id = 1 # runtime
GROUP BY t.id);

  # Add categorical rating to rating
  ALTER TABLE rating
  ADD `rating_cat` char(2) DEFAULT NULL;
  
  UPDATE rating
  SET rating_cat = FLOOR(rating);
  
  ALTER TABLE rating
  ADD `rating_enum` ENUM('excellent', 'average', 'poor', 'terrible');
  
  UPDATE rating
  SET rating_enum = 'excellent'
  WHERE rating >= 7.5;
  
  UPDATE rating
  SET rating_enum = 'average'
  WHERE rating >= 5 AND rating < 7.5;
  
  UPDATE rating
  SET rating_enum = 'poor'
  WHERE rating >= 2.5 AND rating < 5;
  
  UPDATE rating
  SET rating_enum = 'terrible'
  WHERE rating < 2.5;

  
  # Average IMDb rating for actors
  
  CREATE TABLE actor_avg_rating (
   id int(11) unsigned NOT NULL,
   avg_score double NOT NULL,
   count int(11) NOT NULL,
   PRIMARY KEY (id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
 INSERT INTO actor_avg_rating
 SELECT ActorID, AVG(Rating) AS AvgRating, COUNT(*) AS count
 FROM
 (SELECT DISTINCT t.id AS MovieID, r.rating AS Rating, n.id AS ActorID 
 FROM title t
 JOIN cast_info ci ON t.id = ci.movie_id
 JOIN name n ON ci.person_id = n.id
 JOIN rating r ON t.id = r.movie_id
 WHERE ci.role_id BETWEEN 1 AND 2 # Actor or Actress
 AND ci.nr_order BETWEEN 1 AND 10 # Top 10 fra hver film
 ) AS tmp 
 GROUP BY ActorID

   # Average IMDb rating for directors
 
   CREATE TABLE director_avg_rating (
   id int(11) unsigned NOT NULL,
   avg_score double NOT NULL,
   count int(11) NOT NULL,
   PRIMARY KEY (id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
 INSERT INTO director_avg_rating
 SELECT DirectorID, AVG(Rating) AS AvgRating, COUNT(*) AS count
 FROM
 (SELECT DISTINCT t.id AS MovieID, r.rating AS Rating, n.id AS DirectorID 
 FROM title t
 JOIN cast_info ci ON t.id = ci.movie_id
 JOIN name n ON ci.person_id = n.id
 JOIN rating r ON t.id = r.movie_id
 WHERE ci.role_id = 8 # Director
 ) AS tmp 
 GROUP BY DirectorID;
 
 

 
 
