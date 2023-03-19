# Suumo Mailer

- [Overview](#overview)
- [Motivation](#motivation)
- [Limitations](#limitations)
- [Usage](#usage)
- [Tips](#tips)
       
## Overview
- Configure your search on Suumo and copy-paste the url to Suumo Mailer.
- Suumo Mailer will check the url and all subsequent pages every minute for new apartments.
- If new apartments are found, Suumo Mailer sends you an email containing a link e.g. "Open 4 new apartments."
- This link will open two tabs for each new apartment. 
  - Suumo - Apartment details page
  - Google Maps - Apartment address


## Motivation
- The official Suumo notifications are buffered until a certain amount of new apartments were published. The notification email might be sent hours later. Suumo Mailer will email you new apartments one minute after they are published. 
- The "New arrival order" sort order on Suumo is not working correctly. New apartments do not appear first or last. So if you don't want to click through all pages of your search results to find new apartments, use Suumo Mailer instead.
- Suumo does not detect duplicate listings of the apartment. You can get Suumo notification emails including the same apartment uploaded by different agents for weeks.

## Limitations
- Apartments might not actually be new. Suumo Mailer only checks if the *listing* is new. Sometimes you might call a freshly published apartment and 7 people have already applied several days ago.
- When your computer is in sleep mode, Suumo Mailer does nothing.

## Usage
1. Configure your search on Suumo (Open https://suumo.jp/chintai/kanto/ and choose "Along the line" e.g. https://suumo.jp/chintai/tokyo/ensen/ or "Area" e.g. https://suumo.jp/chintai/tokyo/city/).
2. Add your email and the Suumo url via `crontab -e`:

```
# Run "which ruby" and add the path here
PATH=/opt/homebrew/opt/ruby@3.0/bin/ruby

# Don't write output of scrape.rb to disk 
MAILTO=""

# Add (multiple) queries:
# */1 * * * * cd <suumo_mailer_path> && bin/rails runner ./scrape.rb <receiving_email> <suumo_url>

# Example
*/1 * * * * cd /Users/martin/suumo_mailer && bin/rails runner ./scrape.rb martin@gmail.com 'https://suumo.jp/jj/chintai/ichiran/FR301FC001/?ar=030&bs=040&ra=013&rn=0305&ek=030519670&ek=030532110&ek=030527280&ek=030513930&ek=030500640&ek=030506640&ek=030528500&ek=030511640&ek=030536880&ek=030538740&ek=030531920&ek=030538710&ek=030514690&ek=030528740&ek=030512780&ek=030523100&ek=030530660&ek=030529300&ae=03051&cb=0.0&ct=18.0&mb=50&mt=9999999&md=05&md=06&md=07&md=08&md=09&md=10&md=11&md=12&md=13&md=14&et=20&cn=9999999&tc=0401303&shkr1=03&shkr2=03&shkr3=03&shkr4=03&sngz=&po1=09'
```
3. If you don't have the Google App Password for suumomailer@gmail.com, you can create a new google account, an App Password for it and replace all instances of 'suumomailer@gmail.com' with the new email address. The App Password needs to be added in `development.rb`:
```
password:             '<Google App Password for suumomailer@gmail.com>',
```

## Tips
- On Suumo
  - Configure your search to return less than 10 pages.
  - Choose the "Today's New Properties" filter.
- Create a new email address for the sole purpose of receiving these emails.
- Install a mail app with push notifications on your phone.
