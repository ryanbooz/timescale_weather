/* Once the base schema is setup, we can import the city information
 * using the quick process below
 * 
 * First, create a table to hold the imported JSON file
 * 
 * create table city_import (doc jsonb);
 * 
 * Then in psql, the following two commands will import the 
 * large JSON doc into one row of that table.
 * 
 * \set content `cat /Users/ryanbooz/Downloads/city.list.json`;
 * 
 * insert into city_import values (:'content');
 * 
 * From there... do this next...
 * 
 * INSERT INTO city 
select CAST(cities->>'id' AS double precision)::int as id,
	cities->>'name' AS name,
	cities->>'state' AS state,
	cities->>'country' AS country,
	CAST(cities->'coord'->'lat' AS double PRECISION) AS lat,
	CAST(cities->'coord'->'lon' AS double PRECISION)  AS lon
from (select jsonb_array_elements(doc) as cities from city_import) a;

 */

CREATE TABLE city (
	id int NOT NULL PRIMARY key,
	"name" text NULL,
	state text NULL,
	country text NULL,
	lat float8 NULL,
	lon float8 NULL,
	import_data bool DEFAULT false
);



CREATE TABLE weather_type (
	id int NOT NULL PRIMARY key,
	main_type TEXT NOT NULL,
	description TEXT NULL
);

INSERT INTO weather_type VALUES 
	-- Thunderstorms
	(200, 'Thunderstorm','thunderstorm with light rain'),
	(201, 'Thunderstorm','thunderstorm with rain'),
	(202, 'Thunderstorm','thunderstorm with heavy rain'),
	(210, 'Thunderstorm','light thunderstorm'),
	(211, 'Thunderstorm','thunderstorm'),
	(212, 'Thunderstorm','heavy thunderstorm'),
	(221, 'Thunderstorm','ragged thunderstorm'),
	(230, 'Thunderstorm','thunderstorm with light drizzle'),
	(231, 'Thunderstorm','thunderstorm with drizzle'),
	(232, 'Thunderstorm','thunderstorm with heavy drizzle'),
	-- Drizzle
	(300, 'Drizzle','light intensity drizzle'),
	(301, 'Drizzle','drizzle'),
	(302, 'Drizzle','heavy intensity drizzle'),
	(310, 'Drizzle','ligt intensity drizzle rain'),
	(311, 'Drizzle','drizzle rain'),
	(312, 'Drizzle','heavy intensity drizzle rain'),
	(313, 'Drizzle','shower rain and drizzle'),
	(314, 'Drizzle','heavy shower rain and drizzle'),
	(321, 'Drizzle','shower drizzle'),
	-- Rain
	(500, 'Rain','light rain'),
	(501, 'Rain','moderate rain'),
	(502, 'Rain','heavy intensity rain'),
	(503, 'Rain','very heavy rain'),
	(504, 'Rain','extreme rain'),
	(511, 'Rain','freezing rain'),
	(520, 'Rain','light intensity shower rain'),
	(521, 'Rain','shower rain'),
	(522, 'Rain','heavy intensity shower rain'),
	(531, 'Rain','ragged shower rain'),
	-- Snow
	(600, 'Snow','light snow'),
	(601, 'Snow','snow'),
	(602, 'Snow','heavy snow'),
	(611, 'Snow','sleet'),
	(612, 'Snow','light shower sleet'),
	(613, 'Snow','shower sleet'),
	(615, 'Snow','light rain and snow'),
	(616, 'Snow','rain and snow'),
	(620, 'Snow','light shower snow'),
	(621, 'Snow','shower snow'),
	(622, 'Snow','heavy shower snow'),
	-- Atmosphere
	(700, 'Mist','mist'),
	(711, 'Smoke','smoke'),
	(721, 'Haze','haze'),
	(731, 'Dust','sand/dust whirls'),
	(741, 'Fog','fog'),
	(751, 'Sand','sand'),
	(761, 'Dust','dust'),
	(762, 'Ash','volcanic ash'),
	(771, 'Squall','squalls'),
	(781, 'Tornado','tornado'),
	-- Clear!
	(800,'Clear','clear sky'),
	-- Clouds
	(801,'Clouds','few clouds: 11-25%'),
	(802,'Clouds','scattered clouds: 25-50%'),
	(803,'Clouds','broken clouds: 51-84%'),
	(804,'Clouds','overcast clouds: 85-100%');
	

CREATE TABLE IF NOT EXISTS hourly_forecast (
	time timestamptz NOT NULL,
	city_id int NOT NULL,
	temp_c double PRECISION NULL,
	feels_like_c double PRECISION NULL,
	pressure double PRECISION NULL,
	humidity double PRECISION NULL,
	uvi int NULL,
	clouds int NULL,
	visibility int NULL,
	wind_speed double PRECISION NULL,
	wind_deg int NULL,
	rain double PRECISION NULL,
	snow double PRECISION NULL,	
	weather_type_id int NULL,
	CONSTRAINT fk_weather_type FOREIGN KEY (weather_type_id) REFERENCES weather_type(id) ON DELETE NO ACTION,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(id) ON DELETE NO ACTION
);

/*
 * Create a hypertable for the hourly forecast data
 * 
 * I'm not sure what to set the chunk_time_interval to at this point
 * so leaving it at 7 days
 */
SELECT create_hypertable('hourly_forecast','time');


CREATE TABLE IF NOT EXISTS daily_forecast (
	time timestamptz NOT NULL,
	city_id int NOT NULL,
	temp_day_c double PRECISION NULL,
	temp_min_c double PRECISION NULL,
	temp_max_c double PRECISION NULL,
	temp_night_c double PRECISION NULL,
	temp_eve_c double PRECISION NULL,
	temp_morn_c double PRECISION NULL,	
	feels_like_day_c double PRECISION NULL,
	feels_like_night_c double PRECISION NULL,
	feels_like_eve_c double PRECISION NULL,
	feels_like_morn_c double PRECISION NULL,	
	pressure double PRECISION NULL,
	humidity double PRECISION NULL,
	dew_point double PRECISION NULL,
	uvi int NULL,
	clouds int NULL,
	wind_speed double PRECISION NULL,
	wind_deg int NULL,
	rain double PRECISION NULL,
	snow double PRECISION NULL,
	weather_type_id int NULL,
	CONSTRAINT fk_weather_type FOREIGN KEY (weather_type_id) REFERENCES weather_type(id) ON DELETE NO ACTION,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(id) ON DELETE NO ACTION
);


/* 
 * I'm not sure what to set the chunk_time_interval to at this point
 * so leaving it at 7 days
 */
SELECT create_hypertable('daily_forecast','time');


