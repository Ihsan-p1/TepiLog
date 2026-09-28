-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add coordinates column
ALTER TABLE locations ADD COLUMN coordinates GEOGRAPHY(POINT, 4326);

-- Create GIST index for geospatial queries
CREATE INDEX idx_locations_geo ON locations USING GIST(coordinates);

-- Create a function to update coordinates from latitude and longitude
CREATE OR REPLACE FUNCTION update_location_coordinates()
RETURNS TRIGGER AS $$
BEGIN
    NEW.coordinates := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to call the function before INSERT or UPDATE
CREATE TRIGGER trg_update_location_coordinates
BEFORE INSERT OR UPDATE ON locations
FOR EACH ROW
EXECUTE FUNCTION update_location_coordinates();

-- Update existing data if any (just in case)
UPDATE locations SET coordinates = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography;