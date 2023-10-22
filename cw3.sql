CREATE EXTENSION postgis;


-- 4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) 
--    położonych w odległości mniejszej niż 1000 jednostek od głównych rzek. 
--    Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.

SELECT DISTINCT pp.* INTO tableB
FROM popp as pp, majrivers as mr
WHERE pp.f_codedesc = 'Building'
AND ST_DISTANCE(pp.geom, mr.geom) < 1000;

SELECT COUNT(gid) FROM tableB;

-- SELECT * FROM tableB ORDER BY gid ASC

-- 5. Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk,
--    ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

SELECT name, geom, elev INTO airportsNew
FROM airports;

-- SELECT * FROM airportsNew

--- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.
-- wschód
SELECT name FROM airportsNew 
ORDER BY ST_X(geom) DESC
LIMIT 1;

--zachód
SELECT name FROM airportsNew 
ORDER BY ST_X(geom) ASC
LIMIT 1;

--- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym 
---    drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. 
---    Wysokość n.p.m. przyjmij dowolną.
---    Uwaga: geodezyjny układ współrzędnych prostokątnych płaskich (x – oś pionowa, y – oś pozioma)

INSERT INTO airportsNew VALUES
('airportB', 
	(SELECT ST_Centroid
		 (ST_MakeLine((SELECT geom FROM airportsNew ORDER BY ST_X(geom) ASC LIMIT 1),
					  (SELECT geom FROM airportsNew ORDER BY ST_X(geom) DESC LIMIT 1))
		 )
	), 78.000);

--  SELECT * FROM airportsNew WHERE name = 'airportB';
		
-- 6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek 
--    od najkrótszej linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer(ST_ShortestLine(lk.geom, ai.geom), 1000)) as pole_powierzchni
FROM airportsNew as ai, lakes as lk
WHERE ai.name = 'AMBLER'
AND lk.names = 'Iliamna Lake';

-- 7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących 
--    poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).
SELECT tr.vegdesc as typ_drzewa, SUM(ST_AREA(tr.geom)) FROM trees as tr, swamp as sw, tundra as tn
WHERE ST_CONTAINS(sw.geom, tr.geom)
OR ST_CONTAINS(tn.geom, tr.geom)
GROUP BY tr.vegdesc 










