#!/opt/QPython312/bin/python3.12

from pyarr import RadarrAPI

import sys
import os
import pprint

DOWNLOAD_DIR = "/share/Download"
OUTFILE = DOWNLOAD_DIR + "/radarr_monitor_output.log"

HOST_URL = 'REDACTED'
API_KEY = 'REDACTED'

f = open(OUTFILE, 'a')

event = os.environ.get("radarr_eventtype")

f.write("event_type: {}\n".format(event))

if event == "Download":
  movie_id = os.environ.get("radarr_movie_id")
  movie_title = os.environ.get("radarr_movie_title")

  f.write("unmonitoring '{}' (id {})\n".format(movie_title, movie_id))

  radarr = RadarrAPI(HOST_URL, API_KEY)
  update_data = {"movieIds":[movie_id],"monitored":False}
  radarr.upd_movies(update_data)

f.write("------\n")
f.close()
