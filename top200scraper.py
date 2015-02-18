from bs4 import BeautifulSoup
import requests
import csv
import unicodedata

top1000 = []

for start in range(1, 1000, 250):
  r  = requests.get("http://www.imdb.com/list/ls000050027/?start=" + str(start) + "&view=detail&sort=listorian:asc&scb=0.48930723196826875")
  data = r.text
  soup = BeautifulSoup(data)
  actors = soup.find_all('td', {'class':'name'})
  for i, actor in enumerate(actors):
    # Some actors have weird characters in their names
    # Skipping them instead of having to deal with string encodings
    try:
      print(actor.text)
      top1000.append((start+i, actor.text))
    except Exception:
      print("could not convert")


with open('top1000actors.csv', 'w', newline='') as csvfile:
    a = csv.writer(csvfile, delimiter=',')
    a.writerow(["position", "name"])
    a.writerows(top1000)

print("Total:", len(top1000))


