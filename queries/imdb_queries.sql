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


#Spørring for model1

SELECT t.id AS ID, t.title AS Title, genre.info AS Genre, SUBSTRING_INDEX(runtime.info,':',-1) AS Runtime, votes.info AS Votes, 
relmonth.info AS ReleaseMonth, mpaa.info AS MPAA, SUM(top.logscore) AS TotalActorLogScore, SUM(top2.logscore) AS TotalDirectorLogScore, rating.info AS IMDBScore
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN name n ON ci.person_id = n.id
JOIN top1000actors top ON top.name_id = n.id 
JOIN top200directors top2 ON top2.name_id = n.id
JOIN movie_info genre ON t.id = genre.movie_id
JOIN movie_info lang ON t.id = lang.movie_id
JOIN movie_info runtime ON t.id = runtime.movie_id
JOIN movie_info_idx votes ON t.id = votes.movie_id
JOIN movie_info relmonth ON t.id = relmonth.movie_id
JOIN movie_info mpaa ON t.id = mpaa.movie_id
JOIN movie_info_idx rating ON t.id = rating.movie_id
WHERE genre.info_type_id = 3 # genre
AND lang.info_type_id = 4 # language
AND runtime.info_type_id = 1 # runtime
AND votes.info_type_id = 100 # votes
AND relmonth.info_type_id = 16 # release month
AND mpaa.info_type_id = 97 # MPAA
AND rating.info_type_id = 101 # imdb-score
GROUP BY t.id

