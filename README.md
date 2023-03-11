# Suumo Mailer

1. Open https://suumo.jp/chintai/kanto/ and choose "Along the line" e.g. https://suumo.jp/chintai/tokyo/ensen/ or "Area" e.g. https://suumo.jp/chintai/tokyo/city/
2. Configure your search
3. Order by "New arrival order"
4. Add the Suumo url via `crontab -e`

Example:
```
# Run "which ruby" and add the path here
PATH=/opt/homebrew/opt/ruby@3.0/bin/ruby

# Don't write output of scrape.rb to disk 
MAILTO=""

# Check every minute
*/1 * * * * cd /Users/martin/code/suumo_mailer && bin/rails runner ./scrape.rb martin@gmail.com 'https://suumo.jp/jj/chintai/ichiran/FR301FC001/?ar=030&bs=040&ra=013&rn=0305&ek=030519670&ek=030532110&ek=030527280&ek=030513930&ek=030500640&ek=030506640&ek=030528500&ek=030511640&ek=030536880&ek=030538740&ek=030531920&ek=030538710&ek=030514690&ek=030528740&ek=030512780&ek=030523100&ek=030530660&ek=030529300&ae=03051&cb=0.0&ct=18.0&mb=50&mt=9999999&md=05&md=06&md=07&md=08&md=09&md=10&md=11&md=12&md=13&md=14&et=20&cn=9999999&tc=0401303&shkr1=03&shkr2=03&shkr3=03&shkr4=03&sngz=&po1=09'

# Add more queries
# */1 * * * * cd <suumo_mailer> && bin/rails runner ./scrape.rb <mail> <url>

```