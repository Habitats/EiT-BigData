# Bot-detected by google
# does not work :(


# Python 2.7
from bs4 import BeautifulSoup
import grequests
import csv

GOOGLE_URL = "https://www.google.no/search?q="
input_file = "starmeter_actor_rankings.csv"
output_file = "google_and_starmeter_actor_rankings.csv"

actors = []
google_results = []
all_results = []
urls = []

with open(input_file, 'r') as f:
  reader = csv.reader(f)
  next(reader) # Skip header row
  for row in reader:
      actors.append((int(row[0]), row[1])) # starmeter rank, name


for starmeter, actor in actors[:100]:
  search_url = GOOGLE_URL + actor.replace(" ", "+")
  urls.append(search_url)

# Create a set of unsent Requests:
rs = (grequests.get(u, stream=False) for u in urls)

# Send them all at the same time
#grequests.map(rs)

x = grequests.map(rs)

for r in x:
  soup = BeautifulSoup(r.text)
  results = soup.find(id="resultStats")
  print(r.text)
  count = int("".join(filter(unicode.isdigit, results.text)))
  google_results.append(count)

for i in range(1, 100):
  all_results.append(actors[i][1], actors[i][0], google_results[i]) # name, star, google


with open(output_file, 'w', newline='') as csvfile:
  a = csv.writer(csvfile, delimiter=',')
  a.writerow(["actor", "starmeter rank", "google results"])
  a.writerows(all_results)

