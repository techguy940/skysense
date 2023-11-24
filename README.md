# Skysense: Weather & Forecasts
## App Features
### 1. Latest Weather updates and forecasts fetched from an API
### 2. Search for any place and get its weather updates.
### 3. Favourite places and get their weather updates easily.
### 4. Offline data access when user is offline.
### 5. Dynamic icons and backgrounds that change according to the current weather
### 6. UV and AQI Information
### 7. Notifications for weather alerts and updates
### 8. Sunrise and sunset timings.

## App Interface

<p float="left">
 <img src=https://i.imgur.com/AbbOX2s.jpeg width=300 height=800 />
 <img src=https://i.imgur.com/GPEz5cs.jpeg width=300 height=800 />
 <img src=https://i.imgur.com/3syULia.jpeg width=300 height=800 />
 <img src=https://i.imgur.com/wkNqp3N.jpeg width=300 height=800 />
 <img src=https://i.imgur.com/mdAy14b.jpeg width=300 height=800 />
</p>

## APIs used

 - weatherapi.com: Fetch live weather data and hourly forecasts
 - weatherbit.io: Fetch AQI information
 - openweathermap.org: Fetch five-days forecast data
 - positionstack.com: Used for autocomplete places and geocoding.
 
 ## Libraries Used
 
 - permission_handler: Used to handle location permissions
 - google_fonts: Used for changing text font
 - geolocator: Used for getting user's current and last known position
 - http: Used to make API calls
 - intl: Used to standarize and format time
 - shared_preferences: Used to store favourites and most recent data
 - liquid_pull_to_refresh: Used to implement pull-to-refresh
 - awesome_notifications: Used to create and send weather update notifications
 - android_alarm_manager_plus: Used to run weather checks every 30 minutes and update user via notifications
 - flutter_native_splash: Used to implement splash screen
