# Suunto2Strava
"Because the cycling app world is confusing and terrible."

## The Intent
I cycle, both indoors and outdoors. Outdoors, I track my commute and weekend rides with Strava. Indoors, my gym has Precor machines which connect to Preva, which is like a really annoying Strava for Precor.

I want to get that data into Strava.

At first, it looked easy. I can connect Preva to Suunto, some sort of Garmin-like watch company that can then auto-import data into Strava. Hooray! ...Except, Strava flat-out rejects imported files with no gps data (this is also true if I manually export my Suunto data and then import to Strava).

So let's fix all this with code, and get these stupid bike rides into Strava.

## The How

"I'll just use Suunto's API, fetch my data, and then add the GPS that I know to be correct and connect it to Strava's API". Easy peasy. Except, Suunto doesn't provide an open API (neither does Preva). So we'll be doing things the old-fashioned way, with a scraper that runs daily (using `launchd`) and picks up any new changes from Suunto's website. (Shoutout to Suunto for giving me a year-long signin session cookie.)

TODO: How should I know what I've already seen?
Option A: Keep track of it myself. Probably track the id in SQLite.
Option B: Poll Strava first, use something to identify indoor cycles, only get stuff newer than the last of those.

## Shoutout to Strava
For having a real API. ❤️ y'all.