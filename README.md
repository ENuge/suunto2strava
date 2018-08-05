# Suunto2Strava
"Because the cycling app world is confusing and terrible."

### tl;dr
This is a quick script (and an optional scheduler) that fetches all the new activities in Suunto Movescount
since the date specified in `last_successful_run.txt`, and inserts them into
Strava. It then updates that file with today's date. The built-in Strava importer does not work for me because it requires
GPS data, something my stationary workouts don't get (from Preva, Precor's "cloud").

The script makes a bunch of assumptions that work for me, but if you might want something
similar, feel free to generalize it.

## How To Use
**Prerequisites**
1. Clone the repo locally: `git clone https://github.com/ENuge/suunto2strava.git`.
2. Make a couple of files untracked, so git isn't noisy: `git update-index --assume-unchanged .secret/api_keys.rb last_successful_run.rb`.
3. Edit `.secret/api_keys.rb` with your keys. See the *Finding My Keys* section.

As a one-off mass import of all Suunto Movescount data:
1. Change `last_successful_run.txt` to an arbitrary date in the past,
say: `1990-02-04`.
2. Run: `ruby suunto2strava.rb`. (I used Ruby 2.5.1, I don't know which versions it works with. The script requires a handful of gems.)

As a daily import of all new Suunto Movescount data:<br />
**NOTE:** If you know `launchd` better than I do, please fix up the steaming garbage I have here.

1. Update `daily_scheduler.plist` to use the location of your `daily_scheduler.sh`.
2. Update `daily_scheduler.sh` to point to the location of your Ruby executable and where you have `suunto2strava.rb` located.
3. Copy `daily_scheduler.plist` into `/Library/LaunchAgents/`, for me this was: `sudo cp ~/Documents/suunto2strava/daily_scheduler.plist /Library/LaunchAgents/`.
4. Run: `cd /Library/LaunchAgents/ && sudo launchctl load -w daily_scheduler.plist && sudo launchctl start com.suunto2strava.importSuuntoToStrava`.
5. Check the log files specified in `daily_scheduler.plist`, make sure they have some output. If not, open an issue or something.

## Finding My Keys
I'm feeling lazy, so just bear with me:
### Strava API Key
1. Create a Strava app: `https://www.strava.com/settings/api` . Say you're an importer or something.
2. Follow the steps in here, use the access token you get: `https://yizeng.me/2017/01/11/get-a-strava-api-access-token-with-write-permission/`.

### Movescount Cookie
1. Login to [MovesCount](http://www.movescount.com/summary).
2. Open the Chrome Inspector, click `Application`, then copy the `Value` of `MovesCountCookie`. That should keep you authenticated for a year.

## The Intent
I cycle, both indoors and outdoors. Outdoors, I track my commute and weekend rides with Strava. Indoors, my gym has Precor machines which connect to Preva, which is like a really annoying Strava for Precor.

I want to get that data into Strava.

At first, it looked easy. I can connect Preva to Suunto, some sort of Garmin-like watch company that can then auto-import data into Strava. Hooray! ...Except, Strava flat-out rejects imported files with no gps data (this is also true if I manually export my Suunto data and then import to Strava). This is despite Strava's API not even letting me input GPS data of my own (!).

So let's fix all this with code, and get these stupid bike rides into Strava.

## The How

I wanted to not scrape Suunto if possible, so I inspected the network requests and found the direct ajax endpoint called. The cookie works for a year, which is nice. The script fetches that, gets the most recent activities, and POSTs em to Strava.
