#!/opt/QPython312/bin/python3.12

from pyarr import SonarrAPI

import sys
import os
import pprint

DOWNLOAD_DIR = "/share/Download"
OUTFILE = DOWNLOAD_DIR + "/sonarr_monitor_output.log"

HOST_URL = 'REDACTED'
API_KEY = 'REDACTED'

f = open(OUTFILE, 'a')

event = os.environ.get("sonarr_eventtype")

f.write("event_type: {}\n".format(event))

if event == "Download":
  series_id = os.environ.get("sonarr_series_id")
  series_title = os.environ.get("sonarr_series_title")
  season_num = os.environ.get("sonarr_episodefile_seasonnumber")
  episode_nums = os.environ.get("sonarr_episodefile_episodenumbers")

  f.write("unmonitoring '{}' (id {}), season {} episode(s) {}\n".format(series_title, series_id, season_num, episode_nums))

  season_num = int(season_num)
  episode_nums = [int(n) for n in episode_nums.split(",")]

  sonarr = SonarrAPI(HOST_URL, API_KEY)
  series = sonarr.get_series(series_id)
  series_episodes = sonarr.get_episode(series_id, True)
  episodes = [episode for episode in series_episodes if episode['seasonNumber'] == season_num and episode['episodeNumber'] in episode_nums]
  episode_ids = [episode['id'] for episode in episodes]

  sonarr.upd_episode_monitor(episode_ids, False)

f.write("------\n")
f.close()
