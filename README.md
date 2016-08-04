# madridxml2osm
Convierte un XML de datos.madrid.es a formato OSM.

Los XML que procesa esta herramienta son los que tienen etiquetas con este formato:
```
<atributo nombre="ID-ENTIDAD"> 
```
[Ver el listado de los conjuntos de datos](https://wiki.openstreetmap.org/wiki/Import_Ayuntamiento_Madrid)

Uso:
```
./madridxml2osm.sh archivo.xml [LLAVE]=[VALOR]
```
Para procesar el conjunto de datos "Museos de la ciudad de Madrid":
```
./madridxml2osm.sh 201132-0-turismo.xml tourism=museum
```

Estos archivos .osm NO se deben subir directamente a OSM. Si quieres usar el script, por favor coméntalo en la lista talk-es, documenta el proyecto, pon el enlace en la tabla del wiki para poder organizarnos.

Por cada nodo hay que:
* traducir el horario (español -> OSM)
* meter los artículos necesarios entre el "Calle","Avenida",etc y el nombre de la calle.
* reducir y/o formatear la descripción
* combinar estos datos con los nodos que ya existan en OSM

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
