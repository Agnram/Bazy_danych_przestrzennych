---------------------- 3 --------------------------------------------------------

CREATE EXTENSION postgis;

---------------------- 4 --------------------------------------------------------

CREATE TABLE budynki (
	id INT PRIMARY KEY,
	geometria GEOMETRY,
	nazwa VARCHAR(15)
);

CREATE TABLE drogi (
	id INT PRIMARY KEY,
	geometria GEOMETRY,
	nazwa VARCHAR(10)
);

CREATE TABLE punkty_informacyjne (
	id INT PRIMARY KEY,
	geometria GEOMETRY,
	nazwa VARCHAR(5)
);

---------------------- 5 --------------------------------------------------------

INSERT INTO budynki VALUES
(1, ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))'), 'BuildingA'),
(2, ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))'), 'BuildingB'),
(3, ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))'), 'BuildingC'),
(4, ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))'), 'BuildingD'),
(5, ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))'), 'BuildingF');
 
INSERT INTO drogi VALUES
(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'), 'RoadX'),
(2, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)'), 'RoadY')

INSERT INTO punkty_informacyjne VALUES
(1, ST_GeomFromText('POINT(1 3.5)'), 'G'),
(2, ST_GeomFromText('POINT(5.5 1.5)'), 'H'),
(3, ST_GeomFromText('POINT(9.5 6)'), 'I'),
(4, ST_GeomFromText('POINT(6.5 6)'), 'J'),
(5, ST_GeomFromText('POINT(6 9.5)'), 'K')

---------------------- 6 --------------------------------------------------------
-- a. Wyznacz całkowitą długość dróg w analizowanym mieście.

SELECT SUM(ST_Length(geometria)) FROM drogi;

-- b. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA.

SELECT ST_AsText(geometria) as geometria, ST_Area(geometria) as pole_powierzchni, 
ST_Perimeter(geometria) as obwód FROM budynki
WHERE nazwa = 'BuildingA';

-- c. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki.
--    Wyniki posortuj alfabetycznie.
SELECT nazwa, ST_Area(geometria) as pole_powierzchni FROM budynki
ORDER BY nazwa;

-- d. Wypisz nazwy i obwody 2 budynków o największej powierzchni.
SELECT nazwa, ST_Perimeter(geometria) as obwód FROM budynki
ORDER BY obwód DESC
LIMIT 2;

-- e. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.
SELECT ST_Distance(Bd.geometria, pkt.geometria) as odleglosc
FROM budynki as Bd, punkty_informacyjne as pkt
WHERE Bd.nazwa = 'BuildingC' 
AND pkt.nazwa = 'G';


-- f. Wypisz pole powierzchni tej części budynku BuildingC, 
--    która znajduje się w odległości większej niż 0.5 od budynku BuildingB.
SELECT ST_Area (
   ST_Difference(Bd.geometria,
	   ST_Buffer((SELECT geometria FROM budynki WHERE nazwa = 'BuildingD'), 0.5))
	   ) as pole_powierzchni
FROM budynki as Bd WHERE bd.nazwa = 'BuildingC'
		
-- g. Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX. 
SELECT Bd.nazwa FROM budynki as Bd, drogi as Dr
WHERE Dr.nazwa = 'RoadX'
AND ST_Y(ST_Centroid(Bd.geometria)) > ST_Y(ST_Centroid(Dr.geometria))

--    Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych
--    (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

SELECT ST_Area(
	ST_SymDifference(geometria, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))') ) 
)	as pole_powierzchni
FROM budynki WHERE nazwa = 'BuildingC'




 
 
