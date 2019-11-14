-- Rename original string column
ALTER TABLE tour_data RENAME COLUMN recordingtime TO recordingtime_s;

-- Add new DATE column
ALTER TABLE tour_data ADD (recordingtime DATE);

-- Convert Unix timestamp to actual DATE
UPDATE tour_data SET recordingtime  = TO_DATE('1970-01-01','YYYY-MM-DD') + (SUBSTR(recordingtime_s,1,10)/24/60/60);
COMMIT;

-- Add SDO_GEOMETRY column
ALTER TABLE tour_data ADD (geo_location SDO_GEOMETRY);

-- Add Spatial metadata
INSERT INTO user_sdo_geom_metadata VALUES (
'TOUR_DATA',  -- table name
'GEO_LOCATION',  -- geometry column name
MDSYS.SDO_DIM_ARRAY( 
 MDSYS.SDO_DIM_ELEMENT('x', -180, 180, 0.05), 
 MDSYS.SDO_DIM_ELEMENT('y', -90, 90, 0.05)),
4326  -- coordinate system id (4326 for lat/lon)
);
COMMIT;

-- Create Spatial index
CREATE INDEX tour_data_sidx_001 ON tour_data(geo_location)
   INDEXTYPE IS MDSYS.SPATIAL_INDEX;

-- Insert geo coordinates into SDO_GEOMETRY column
UPDATE tour_data
   SET geo_location = SDO_GEOMETRY(2001, 4326, 
                         SDO_POINT_TYPE(JSON_VALUE(recording, '$.lng'), JSON_VALUE(recording, '$.lat'), null), null,null);
COMMIT;