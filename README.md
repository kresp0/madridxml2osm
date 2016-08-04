# madridxml2osm
Convierte un xml de datos.madrid.es a formato osm.

Los XML que procesa esta herramienta son los que tienen etiquetas con este formato:
```
<atributo nombre="ID-ENTIDAD"> 
```
Uso:
```
./madridxml2osm.sh archivo.xml [LLAVE]=[VALOR]
```
Ejemplo:
```
./madridxml2osm.sh 201132-0-turismo.xml tourism=museum
```
Esto genera un archivo .osm que NO hay que subir directamente a OSM, pues por cada nodo hay que:

* traducir la fecha (español -> OSM)
* meter los artículos necesarios entre el "Calle","Avenida",etc y el nombre de la calle.
* reducir la descripción si es demasiado larga

| Etiquetas Ayuntamiento | Etiquetas OSM |
| ---------------------- | :-----------: |
| NOMBRE                 | name |
| DESCRIPCION + DESCRIPCION-ENTIDAD + EQUIPAMIENTO | description |
| HORARIO                | opening_hours |
| TELEFONO               | phone |
| FAX                    | fax |
| CLASE-VIAL + "FIXME" + NOMBRE-VIA | addr:street |
| NUM                    | addr:housenumber |
| CODIGO-POSTAL          | addr:postcode |
| LOCALIDAD              | addr:city  |
| PROVINCIA              | addr:province |
| BARRIO                 | addr:suburb |
| DISTRITO               | addr:district |
| ACCESIBILIDAD          | wheelchair=yes/no |
| CONTENT-URL            | url |


Dependencias:
```
apt-get install xsltproc
```
