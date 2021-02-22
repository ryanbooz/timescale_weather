from pyowm import OWM
from pyowm.utils import config
from pyowm.utils import timestamps
import psycopg2
from pgcopy import CopyManager

import json

conn_string = "postgres://postgres:timescale@localhost/postgres"
# Replace with your OWM API key
owm = OWM('abc123')

# Forecast data
def retrieve_forecast():
    request = list()
    hour_cols = ('time','city_id', 'temp_c','feels_like_c','pressure','humidity','uvi','clouds',
            'visibility','wind_speed','wind_deg','rain', 'snow', 'weather_type_id')

    daily_cols = ('time','city_id', 'temp_day_c', 'temp_min_c', 'temp_max_c', 'temp_night_c', 'temp_eve_c', 'temp_morn_c',
                    'feels_like_day_c', 'feels_like_night_c', 'feels_like_eve_c', 'feels_like_morn_c','pressure','humidity',
                    'dew_point','uvi','clouds','wind_speed','wind_deg','rain','snow','weather_type_id')

    # for each city, call for the 'one call' data and then retrieve
    # the hourly and daily forecast
    for k,y in city_dict.items():
        oc = wm.one_call(lon=y['lon'],lat=y['lat'],exclude='minutely',units='metric')
        hf = oc.forecast_hourly
        df = oc.forecast_daily
        station_id = y['id']

        # hourly forecast - 48 hours per city
        for hour in hf:
            ref_time = hour.reference_time('date')
            temp_c=hour.temperature().get('temp',None)
            feels_like_c = hour.temperature().get('feels_like',None)
            pressure = int(hour.pressure.get('press',None))
            humidity=int(hour.humidity)
            uvi = int(hour.uvi)
            clouds = int(hour.clouds)
            visibility=int(hour.visibility_distance)
            wind_speed = hour.wind().get('wind_speed',None)
            wind_deg = hour.wind().get('wind_deg',None)
            weather_type_id = int(hour.weather_code)
            snow = hour.snow.get('1h',None)
            rain = hour.rain.get('1h',None)
            request.append((ref_time, station_id, temp_c, feels_like_c, pressure,
                            humidity, uvi, clouds, visibility, wind_speed, wind_deg, rain, snow, weather_type_id))

        # For this city, once all of the hours are
        # iterated, save the data and then work on the 
        # daily values
        with psycopg2.connect(conn_string) as conn:
            mgr = CopyManager(conn, 'hourly_forecast', hour_cols)
            mgr.copy(request)

        # Clear the list from hourly values
        request.clear()

        # Now retrieve the daily forecast data for this location
        for day in df:
            ref_time = day.reference_time('date')
            temp_day_c=day.temperature().get('day',None)
            temp_min_c=day.temperature().get('min',None)
            temp_max_c=day.temperature().get('max',None)
            temp_night_c=day.temperature().get('night',None)
            temp_eve_c=day.temperature().get('eve',None)                                                
            temp_morn_c=day.temperature().get('morn',None)                                                
            feels_like_day_c = day.temperature().get('feels_like_day',None)
            feels_like_night_c = day.temperature().get('feels_like_night',None)
            feels_like_eve_c = day.temperature().get('feels_like_eve',None)
            feels_like_morn_c = day.temperature().get('feels_like_morn',None)                                    
            pressure = day.pressure.get('press',None)
            humidity=int(day.humidity)
            dew_point=day.dewpoint
            uvi = int(day.uvi)
            clouds = int(day.clouds)
            wind_speed = day.wind().get('wind_speed',None)
            wind_deg = day.wind().get('wind_deg',None)
            weather_type_id = int(day.weather_code)
            snow = day.snow.get('all',None)
            rain = day.rain.get('all',None)
            request.append((ref_time, station_id, temp_day_c, temp_min_c, temp_max_c, temp_night_c, temp_eve_c, temp_morn_c,
                            feels_like_day_c, feels_like_night_c, feels_like_eve_c, feels_like_morn_c, pressure,
                            humidity, dew_point, uvi, clouds, wind_speed, wind_deg, rain, snow, weather_type_id))

        # Save hourly forecast data
        with psycopg2.connect(conn_string) as conn:
            mgr = CopyManager(conn, 'daily_forecast', daily_cols)
            mgr.copy(request)

        # clear for the next loop
        request.clear()
        


if __name__ == "__main__":
    # Populate dict variables when program initialized
    city_dict = {}
    wm = owm.weather_manager()

    with psycopg2.connect(conn_string) as conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT id, name, lat, lon FROM city WHERE import_data = true")
            for id, name, lat, lon in cursor.fetchall():
                print('Name: '+ name + ', LAT: '+ str(lat)+ ', LON:'+ str(lon))
                city_dict[name] = {'id':id, 'lat': lat, 'lon': lon}
            cursor.close()
        except (Exception, psycopg2.Error) as error:
            print("Error thrown while trying to populate cache")
            print(error)

    retrieve_forecast()