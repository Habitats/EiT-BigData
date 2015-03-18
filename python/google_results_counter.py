from bs4 import BeautifulSoup
import requests
import csv
import os

GOOGLE_URL = "https://www.google.no/search?q="
input_file = "starmeter_actor_rankings.csv"
output_file = "google_and_starmeter_actor_rankings.csv"

actors = []
actor_results = []
start_index = 0

def google_count(search_term):
  # Find the number of search results for given search term
  search_url = GOOGLE_URL + '"' + search_term.replace(" ", "+") + '"'
  r  = requests.get(search_url)
  soup = BeautifulSoup(r.text)
  results = soup.find(id="resultStats")
  count = int("".join(filter(unicode.isdigit, results.text)))
  return count


# Create output file if not exists
if not os.path.isfile(output_file):
  with open(output_file, 'w') as csvfile:
    a = csv.writer(csvfile, delimiter=',')
    a.writerow(["actor", "starmeter rank", "google results"])
  print("New file")
else:
  with open(output_file, 'r') as f:
    start_index = max(0,len(f.readlines())-1)
  print("File exists, starting at starmeter rank: " + str(start_index))

# Read starmeter ranks and actors
with open(input_file, 'rb') as f:
  reader = csv.reader(f)
  next(reader) # Skip header row
  for row in reader:
      actors.append((int(row[0]), row[1])) # starmeter rank, name

with open(output_file, 'ab') as csvfile:
  a = csv.writer(csvfile, delimiter=',')
  i = 0
  for starmeter_rank, actor in actors[start_index:]:
    a.writerow((actor, starmeter_rank, google_count(actor)))
    if i%10 == 0:
      csvfile.flush()
      print(i)
    i += 1

