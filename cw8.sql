CREATE EXTENSION postgis;

CREATE EXTENSION postgis_raster;

---------------------- 3 ---------------------------
-- Utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON public.uk_250k 
USING gist (ST_ConvexHull(rast));

-- Dodanie raster constraints:
SELECT AddRasterConstraints('public'::name, 'uk_250k'::name,'rast'::name);

---------------------- 6 ---------------------------

CREATE TABLE uk_lake_district AS 
SELECT ST_Clip(uk.rast, np.geom, true) as rast
FROM uk_250k as uk, national_parks as np
WHERE np.id = 1 and ST_Intersects(np.geom, uk.rast)

---------------------- 7 ---------------------------
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0, ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM uk_lake_district

SELECT lo_export(loid, 'D:\uk_lake_district.tiff') 
FROM tmp_out;

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;

---------------------- 10 ---------------------------
-- SELECT ST_SRID(rast) FROM sentinel_b03_2 
-- SELECT ST_SRID(geom) FROM national_parks
	
CREATE TABLE nirr AS 
SELECT ST_Union(rast) AS rast
FROM (SELECT rast FROM sentinel_b08
	  UNION ALL 
	  SELECT rast FROM sentinel_b08_2) b8;

CREATE TABLE green AS 
SELECT ST_Union(rast) AS rast
FROM (SELECT rast FROM sentinel_b03 
	  UNION ALL
      SELECT rast FROM sentinel_b03_2) b3;


WITH 
r3 AS (
(SELECT ST_Clip(gr.rast, ST_Transform(np.geom, 32630), true) as rast
	FROM green AS gr, national_parks AS np
	WHERE  np.id=1 AND ST_Intersects(gr.rast, ST_Transform(np.geom, 32630)) )
),
r8 AS (
(SELECT ST_Clip(nr.rast, ST_Transform(np.geom, 32630), true) as rast
	FROM nirr AS nr, national_parks AS np
	WHERE ST_Intersects(nr.rast, ST_Transform(np.geom, 32630)) AND np.id = 1))

SELECT ST_MapAlgebra(r3.rast, r8.rast, '([rast1.val]-[rast2.val])/([rast1.val]+[rast2.val])::float', '32BF') AS rast
INTO lake_district_ndwi
FROM r3, r8;

---------------------- 11 ---------------------------

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM public.lake_district_ndwi;

SELECT lo_export(loid, 'D:\uk_lake_district_ndwi.tif')
FROM tmp_out;

SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;








