# Python 3
from bs4 import BeautifulSoup
import requests
import csv

""" 
  This script downloads the top n actors from the imdb starmeter
  website, and saves them to file
"""

STARMETER_URL = "http://www.imdb.com/search/name?gender=male,female&start="
PER_PAGE = 50
TOTAL = 10000
output_file = "starmeter_actor_rankings.csv"

starmeter_ranks = []
for start in range(1, TOTAL+1, PER_PAGE):
  r  = requests.get(STARMETER_URL + str(start))
  r.encoding = "utf-8" # Important: support for special characters

  soup = BeautifulSoup(str(r.text))
  actors = soup.find_all('td', {'class':'name'})
  for i, actor in enumerate(actors):
    print(actor.a.text)
    starmeter_ranks.append((start+i, actor.a.text)) # position, name of the actor

with open(output_file, 'w', newline='') as csvfile:
  a = csv.writer(csvfile, delimiter=',')
  a.writerow(["starmeter_rank", "name"])
  a.writerows(starmeter_ranks)