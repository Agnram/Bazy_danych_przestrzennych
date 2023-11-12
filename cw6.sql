CREATE EXTENSION postgis;

--------------------------------------------------------------------
-- 1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej.
--    Układ odniesienia ustal jako niezdefiniowany. 
--    Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT.

CREATE TABLE obiekty (
	id INT PRIMARY KEY,
	nazwa VARCHAR(10),
	geom GEOMETRY
	
);

-- obiekt1
INSERT INTO obiekty VALUES 
(1, 'obiekt1', 
 ST_GeomFromEWKT('COMPOUNDCURVE((0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))'));

-- obiekt2
INSERT INTO obiekty VALUES 
(2, 'obiekt2', 
 ST_GeomFromEWKT('CURVEPOLYGON(
					 COMPOUNDCURVE((10 2, 10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2, 12 0, 10 2)), CIRCULARSTRING(11 2, 12 3, 13 2, 12 1, 11 2))'));

-- obiekt3
INSERT INTO obiekty VALUES 
(3, 'obiekt3', ST_GeomFromEWKT('TRIANGLE( (10 17, 12 13, 7 15, 10 17) )' ));

-- obiekt4
INSERT INTO obiekty VALUES 
(4, 'obiekt4', ST_GeomFromEWKT('MULTILINESTRING( (20 20, 25 25, 27 24, 25 22), (25 22, 26 21, 22 19), (22 19, 20.5 19.5) )' ));

-- obiekt5
INSERT INTO obiekty VALUES 
(5, 'obiekt5', ST_GeomFromEWKT('MULTIPOINT ((30 30 59), (38 32 234))' ));

-- obiekt6
INSERT INTO obiekty VALUES 
(6, 'obiekt6', ST_GeomFromEWKT('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))'));

-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek,
--    który został utworzony wokół najkrótszej linii łączącej obiekt 3 i 4.

SELECT ST_Area(ST_Buffer(ST_ShortestLine(o3.geom, o4.geom), 5)) as pole
FROM obiekty as o3, obiekty as o4
WHERE o3.nazwa = 'obiekt3'
AND o4.nazwa = 'obiekt4'

-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można 
--    było wykonać to zadanie? Zapewnij te warunki.

-- Czy jest domknięty?
SELECT ST_IsClosed(geom) FROM obiekty
WHERE nazwa = 'obiekt4'

UPDATE obiekty
SET geom = ST_MakePolygon(ST_LineMerge(ST_Collect(geom, 'LINESTRING(20.5 19.5,20 20)')))
WHERE nazwa='obiekt4';

-- SELECT ST_AsText(geom) FROM obiekty WHERE nazwa='obiekt4';

-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty VALUES 
(7, 'obiekt7', 
 	(SELECT ST_Collect(o4.geom, o3.geom) FROM obiekty as o3, obiekty as o4 
 	WHERE o3.nazwa = 'obiekt3' AND o4.nazwa = 'obiekt4')

);

-- SELECT ST_AsText(geom) FROM obiekty WHERE nazwa='obiekt7';

-- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, 
--    które zostały utworzone wokół obiektów nie zawierających łuków.
SELECT Sum(ST_Area(ST_BUFFER(geom, 5))) as pole_powierzchni FROM obiekty 
WHERE ST_HasArc(geom) = false;











