from bs4 import BeautifulSoup
import requests
import csv

GOOGLE_URL = "https://www.google.no/search?q="
input_file = "starmeter_actor_rankings.csv"
output_file = "google_and_starmeter_actor_rankings9000.csv"

actors = []
actor_results = []

def google_count(search_term):
  # Find the number of search results for given search term
  search_url = GOOGLE_URL + '"' + search_term.replace(" ", "+") + '"'
  print(search_url)
  r  = requests.get(search_url)
  soup = BeautifulSoup(r.text)
  results = soup.find(id="resultStats")
  count = int("".join(filter(unicode.isdigit, results.text)))
  return count

with open(input_file, 'rb') as f:
  reader = csv.reader(f)
  next(reader) # Skip header row
  for row in reader:
      actors.append((int(row[0]), row[1])) # starmeter rank, name

with open(output_file, 'wb') as csvfile:
  a = csv.writer(csvfile, delimiter=',')
  a.writerow(["actor", "starmeter rank", "google results"])
  i = 0
  for starmeter_rank, actor in actors[9000:]:
    a.writerow((actor, starmeter_rank, google_count(actor)))
    if i%100 == 0:
      csvfile.flush()
      print(i)
    i += 1

