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

SELECT m.info
FROM title t
JOIN movie_info m ON m.movie_id = t.id
JOIN info_type ty ON m.info_type_id = ty.id
WHERE t.title ='Inception'
AND ty.info = 'gross'
AND m.info LIKE '%Worldwide%'