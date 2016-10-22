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

  #ACTOR_SCORES

	CREATE TABLE actor_scores (
	   id int(11) unsigned NOT NULL AUTO_INCREMENT,
	   movie_id int(11) DEFAULT NULL,
	   score int(11) NOT NULL,
	   logscore double NOT NULL,
	   count int(11) NOT NULL,
	   PRIMARY KEY (id),
	   CONSTRAINT actor_scores_movie_id_fk FOREIGN KEY (movie_id) REFERENCES title (id) ON DELETE CASCADE
	 ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8; 
	 
	SET @rank=0;
	INSERT INTO actor_scores(
	SELECT @rank:=@rank+1 AS rank, t.id AS ID,
	SUM(top.score) AS score,
	SUM(top.logscore) AS logscore,
	COUNT(*) AS count
	FROM title t
	JOIN cast_info ci ON t.id = ci.movie_id
	JOIN name n ON ci.person_id = n.id
	JOIN top1000actors top ON top.name_id = n.id 
	WHERE ci.role_id BETWEEN 1 AND 2
	GROUP BY t.id);

#DIRECTOR_SCORES

	CREATE TABLE director_scores (
	   id int(11) unsigned NOT NULL AUTO_INCREMENT,
	   movie_id int(11) DEFAULT NULL,
	   score int(11) NOT NULL,
	   logscore double NOT NULL,
	   PRIMARY KEY (id),
	   CONSTRAINT director_scores_movie_id_fk FOREIGN KEY (movie_id) REFERENCES title (id) ON DELETE CASCADE
	 ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8; 
	 
	SET @rank=0;
	INSERT INTO director_scores(
	SELECT @rank:=@rank+1 AS rank, t.id AS ID,
	AVG(top.score) AS score,
	AVG(top.logscore) AS logscore
	FROM title t
	JOIN cast_info ci ON t.id = ci.movie_id
	JOIN name n ON ci.person_id = n.id
	JOIN top200directors top ON top.name_id = n.id 
	WHERE ci.role_id = 8
	GROUP BY t.id);
  
  
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
 
 # Average actor-rating for hver film
 
   CREATE TABLE actor_scores_imdb (
   movie_id int(11) unsigned NOT NULL,
   avg_actor_score double NOT NULL,
   PRIMARY KEY (movie_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
 
 INSERT INTO actor_scores_imdb
 SELECT movieID, AVG(actor_score)
 FROM
 (SELECT DISTINCT t.id AS movieID, r.avg_score AS actor_score, n.id AS actorID
 FROM title t
 JOIN cast_info ci ON t.id = ci.movie_id
 JOIN name n ON ci.person_id = n.id
 JOIN actor_avg_rating r ON r.id = n.id
 WHERE ci.role_id BETWEEN 1 AND 2
 AND ci.nr_order BETWEEN 1 AND 10 ) AS tmp
 GROUP BY movieID
 
 # Average director-rating for hver film
 
   CREATE TABLE director_scores_imdb (
   movie_id int(11) unsigned NOT NULL,
   avg_director_score double NOT NULL,
   PRIMARY KEY (movie_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
 
 INSERT INTO director_scores_imdb
 SELECT movieID, AVG(director_score)
 FROM
 (SELECT DISTINCT t.id AS movieID, r.avg_score AS director_score, n.id AS actorID
 FROM title t
 JOIN cast_info ci ON t.id = ci.movie_id
 JOIN name n ON ci.person_id = n.id
 JOIN director_avg_rating r ON r.id = n.id
 WHERE ci.role_id = 8) AS tmp
 GROUP BY movieID;

 
#Legge inn google og starmeter i databasen
 
LOAD DATA LOCAL INFILE 'c:/google_and_starmeter_actor_rankings.csv'
INTO TABLE actors_starmeter_google
FIELDS TERMINATED BY ',' 
ENCLOSED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS(name,starmeter_position,google_results);

#Legge til person-id i tabellen

UPDATE actors_starmeter_google a 
JOIN name n ON n.name2 = a.name 
SET a.person_id = n.id
 
# Add categorical runtimes to runtime
  ALTER TABLE runtimes
  ADD `runtime_enum` ENUM('Very Short', 'Short', 'Medium', 'Long');
  
  UPDATE runtimes
  SET runtime_enum = 'Very Short'
  WHERE runtime BETWEEN 0 AND 50;
  
  UPDATE runtimes
  SET runtime_enum = 'Short'
  WHERE runtime BETWEEN 51 AND 90;
  
  UPDATE runtimes
  SET runtime_enum = 'Medium'
  WHERE runtime BETWEEN 90 AND 120;
  
  UPDATE runtimes
  SET runtime_enum = 'Long'
  WHERE runtime > 120;

# Google-score, normalisert
  
SET @maax= (SELECT MAX(log(google_results)) FROM actors_starmeter_google);

UPDATE actors_starmeter_google a 
SET a.google_score = log(a.google_results)/@maax;


# Average actor-rating3 for hver film
 
CREATE TABLE actor_scores_stargoogle (
   movie_id int(11) unsigned NOT NULL,
   starmeter double NOT NULL,
   google double NOT NULL,
   PRIMARY KEY (movie_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
 
 INSERT INTO actor_scores_stargoogle
 SELECT movieID, SUM(star), SUM(google) 
 FROM
 (SELECT DISTINCT t.id AS movieID,  n.id AS actorID,
 a.starmeter_score AS star,
 a.google_score AS google
 FROM title t
 JOIN cast_info ci ON t.id = ci.movie_id
 JOIN name n ON ci.person_id = n.id
 JOIN actors_starmeter_google a ON a.person_id = n.id
 WHERE ci.role_id BETWEEN 1 AND 2
 AND ci.nr_order BETWEEN 1 AND 10 ) AS tmp
 GROUP BY movieID

## VIEWS basert på samme filmer (46454 stk)
## Kun filmer med verdier for rating og budsjett

CREATE TABLE view_maker AS
SELECT t.id AS ID, t.title AS Title, l.language AS Language,
r.runtime AS Runtime, r.runtime_enum AS RuntimeCategory, mpaa.mpaa AS MPAA,
rm.release_month AS ReleaseMonth, 
IFNULL(top.score,0) AS TotalActorScore, IFNULL(top2.score,0) AS TotalDirectorScore,
asi.avg_actor_score AS TotalActorScore2, dsi.avg_director_score AS TotalDirectorScore2,
IFNULL(star.starmeter,0) AS TotalStarMeterScore, IFNULL(star.google,0) AS TotalGoogleScore,
v.votes AS Votes, ra.rating AS Rating,ra.rating_cat AS IntegerRating, ra.rating_enum AS RatingCategory,
bu.usd_budget AS UsdBudget, bu.i_adj_usd_budget AS UsdAdjBudget, gr.usd_gross AS UsdGross,
gr.i_adj_usd_gross AS UsdAdjGross, AVG(gs.avg_rating) AS GenreRating
FROM title t
JOIN rating ra ON t.id = ra.movie_id
LEFT JOIN language l ON t.id = l.movie_id
LEFT JOIN genres g ON t.id = g.movie_id
LEFT JOIN runtimes r ON t.id = r.movie_id
LEFT JOIN mpaa_ratings mpaa ON t.id = mpaa.movie_id
LEFT JOIN release_month rm ON t.id = rm.movie_id
LEFT JOIN actor_scores_imdb asi ON asi.movie_id = t.id 
LEFT JOIN director_scores_imdb dsi ON dsi.movie_id = t.id 
LEFT JOIN actor_scores top ON top.movie_id = t.id 
LEFT JOIN director_scores top2 ON top2.movie_id = t.id 
LEFT JOIN actor_scores_stargoogle star ON star.movie_id = t.id 
LEFT JOIN votes v ON t.id = v.movie_id
JOIN budget bu ON t.id = bu.movie_id
LEFT JOIN gross gr ON t.id = gr.movie_id
LEFT JOIN genre_score gs ON g.genres = gs.genre
GROUP BY t.id;

# View model1

CREATE VIEW model1
AS (
SELECT ID, Title, Runtime, MPAA, ReleaseMonth, TotalActorScore,
TotalDirectorScore, RatingCategory
FROM view_maker
);

# View model2

CREATE VIEW model2
AS (
SELECT ID, Title, RuntimeCategory, TotalActorScore2,
TotalDirectorScore2, Language, UsdAdjBudget, GenreRating, RatingCategory
FROM view_maker
);

# View model3

CREATE VIEW model3
AS (
SELECT ID, Title,
TotalActorScore2,TotalDirectorScore2, UsdAdjBudget,
(SELECT CASE
WHEN UsdAdjGross<=exp(13) THEN 'Low'
WHEN UsdAdjGross>exp(13) AND UsdAdjGross<=exp(17) THEN 'Medium'
WHEN UsdAdjGross>exp(17) THEN 'High' END) AS UsdAdjGross
FROM view_maker
);

# View model4

CREATE VIEW model4
AS (
SELECT ID, Title,
TotalStarMeterScore, TotalGoogleScore, TotalDirectorScore2, UsdAdjBudget,
(SELECT CASE
WHEN UsdAdjGross<=exp(13) THEN 'Low'
WHEN UsdAdjGross>exp(13) AND UsdAdjGross<=exp(17) THEN 'Medium'
WHEN UsdAdjGross>exp(17) THEN 'High' END) AS UsdAdjGross
FROM view_maker
);

 