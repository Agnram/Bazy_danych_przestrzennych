CREATE EXTENSION postgis;

--------------------------------------------------------------------
-- 1. Zaimportuj następujące pliki shapefile do bazy, przyjmij wszędzie układ WGS84:
--    - T2018_KAR_BUILDINGS  - T2019_KAR_BUILDINGS
--    Pliki te przedstawiają zabudowę miasta Karlsruhe w latach 2018 i 2019.
--    Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019).


SELECT * INTO buildings_changed FROM (
	-- zmienione
SELECT t19.* 
FROM t2018_kar_buildings as t18, t2019_kar_buildings as t19
WHERE NOT ST_Equals (t18.geom, t19.geom)
AND t18.polygon_id = t19.polygon_id
	UNION ALL
 	-- nowe
SELECT t19.* 
FROM t2019_kar_buildings as t19
WHERE NOT EXISTS (SELECT t18.polygon_id FROM t2018_kar_buildings as t18 
				 WHERE t18.polygon_id = t19.polygon_id)
) as b_c;

SELECT COUNT(*) as zmienione_budynki FROM buildings_changed


-- 2. Zaimportuj dane dotyczące POIs (Points of Interest) z obu lat:
--    - T2018_KAR_POI_TABLE - T2019_KAR_POI_TABLE
--    Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub
--    wybudowanych budynków, które znalezione zostały w zadaniu 1. 
--    Policz je wg ich kategorii.

SELECT DISTINCT t19_p.type,  COUNT(t19_p.*) 
FROM t2019_kar_poi_table as t19_p, buildings_changed as bc
WHERE ST_CoveredBy(t19_p.geom, ST_Buffer(bc.geom, 500) )
AND NOT EXISTS (SELECT t18_p.poi_id FROM t2018_kar_poi_table as t18_p 
				 WHERE t18_p.poi_id = t19_p.poi_id)
GROUP BY t19_p.type;

-- 3. Utwórz nową tabelę o nazwie ‘streets_reprojected’,
--    która zawierać będzie dane z tabeli T2019_KAR_STREETS 
--    przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.

SELECT gid, link_id, st_name, ref_in_id, nref_in_id, func_class, speed_cat, fr_speed_l,
to_speed_l, dir_travel, ST_Transform(geom, 3068) as geom
INTO streets_reprojected
FROM t2019_kar_streets;


-- 4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
--    Użyj następujących współrzędnych:
--    X Y
--    8.36093 49.03174
--    8.39876 49.00644
--    Przyjmij układ współrzędnych GPS.

CREATE TABLE input_points (
	id INT PRIMARY KEY,
	name VARCHAR(25),
	geom GEOMETRY
);

INSERT INTO input_points VALUES
	(1, 'PointA',  ST_GeomFromText(('POINT(8.36093 49.03174)'), 4326)),
	(2, 'PointB',  ST_GeomFromText(('POINT(8.39876 49.00644)'), 4326));

-- SELECT name, ST_AsText(geom) FROM input_points;

-- 5. Zaktualizuj dane w tabeli ‘input_points’ tak,
--    aby punkty te były w układzie współrzędnych DHDN.Berlin/Cassini. 
--    Wyświetl współrzędne za pomocą funkcji ST_AsText().

ALTER TABLE input_points ALTER COLUMN geom 
TYPE Geometry(Point, 3068) 
USING ST_Transform(geom, 3068);

SELECT ST_AsText(geom), ST_Srid(geom) FROM input_points;


-- 6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m 
--    od linii zbudowanej z punktów w tabeli ‘input_points’. 
--    Wykorzystaj tabelę T2019_STREET_NODE. 
--    Dokonaj reprojekcji geometrii, aby była zgodna z resztą tabel.

-- w 3068 
SELECT * FROM t2019_kar_street_node as str_n
WHERE ST_DWithin(ST_Transform(str_n.geom, 3068), 
				  (SELECT ST_MakeLine(geom) FROM input_points), 200.0)
	
-- w 4326 
SELECT * FROM t2019_kar_street_node as str_n
WHERE ST_DWithin(str_n.geom, 
		        (SELECT ST_MakeLine(ST_Transform(geom, 4326)) 
				 FROM input_points), 200.0, true)
				 
	
-- 7. Policz jak wiele sklepów sportowych 
--    (‘Sporting Goods Store’ - tabela POIs) znajduje się w odległości 300 m od parków 
--    (LAND_USE_A).

SELECT COUNT(pt.gid) as liczba_sklepów FROM t2019_kar_poi_table as pt, t2019_kar_land_use_a as lua
WHERE pt.type = 'Sporting Goods Store'
AND lua.type = 'Park (City/County)'
AND ST_DWithin(pt.geom, lua.geom, 300.0, true )

-- 8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). 
--    Zapisz znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.

SELECT DISTINCT ST_Intersection(w.geom, r.geom) as geom 
INTO T2019_KAR_BRIDGES
FROM t2019_kar_railways as r, t2019_kar_water_lines as w;

SELECT ST_AsText(geom) FROM T2019_KAR_BRIDGES;












