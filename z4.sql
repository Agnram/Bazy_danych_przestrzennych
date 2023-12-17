CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

-----------------------------------------------------------

SELECT ST_Union(geom) 
INTO scalone
FROM public."Exports" ;