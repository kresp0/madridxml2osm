#!/bin/bash
# Convierte un xml de datos.madrid.es a formato osm
# El xml debe ser del tipo que tiene tags <atributo nombre="ID-ENTIDAD">
# Dependencias:
# apt-get install xsltproc

if [ "$#" -ne 2 ]; then
    echo 'Uso: '$0' archivo.xml [LLAVE]=[VALOR]'
    echo 'Ejemplo: '$0' 201132-0-turismo.xml tourism=museum'
    exit 1
fi

xsltproc -V >/dev/null 2>&1 || { echo >&2 "Error: Hace necesitas instalar xsltproc."; echo ""; echo "sudo apt-get install xsltproc -y"; exit 1; }

LLAVE=`echo $2 | awk -F '=' '{print $1}'`
VALOR=`echo $2 | awk -F '=' '{print $2}'`

XML=$1
OUT_FILE=`grep "<infoDataset" -A1 $XML  | tail -n1 | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' | perl -pe 's/ /_/g'`

echo "Procesando conjunto de datos: $OUT_FILE" | perl -pe 's/_/ /g'

# preprocesamiento xml
perl -pe 's/<!\[CDATA\[//g' $XML | perl -pe 's/]]>//g' |  perl -pe 's/atributo nombre=//g'  | tr -d '"' |  sed '/^\s*$/d' | sed '1,9d' | perl -pe 's/>\n/XXXXX/g' | perl -pe 's/\n//g' | perl -pe 's/XXXXX/>\n/g' | grep -vi '<tipo>' | grep -v atributos | grep -v DATOSCONTACTOS | grep -v LOCALIZACION | grep -v "atributos idioma" > /tmp/$OUT_FILE.xml

# ampersands
perl -pe 's/&/--FIXME--/g' /tmp/$OUT_FILE.xml > /tmp/foo ; mv /tmp/foo /tmp/$OUT_FILE.xml

echo "<catalogo>" > $OUT_FILE-clean.xml
while IFS='' read -r line || [[ -n "$line" ]]; do

  if echo $line | egrep --quiet "^<[A-Z]" ; then
	if echo $line | grep --quiet '<' ; then
	  CLAVE=`echo $line | awk -F '<' '{print $2}' | awk -F '>' '{print $1}'`
      echo $line | perl -pe "s/atributo/"$CLAVE"/g" >> $OUT_FILE-clean.xml
	else
	  echo $line >> $OUT_FILE-clean.xml
	fi
  fi
done < /tmp/$OUT_FILE.xml

perl -pe 's/<ID-ENTIDAD>/<\/contenido><contenido><ID-ENTIDAD>-/g' $OUT_FILE-clean.xml | sed '0,/<\/contenido>/s///' > /tmp/foo ; mv /tmp/foo $OUT_FILE-clean.xml
echo "</contenido> </catalogo>" >> $OUT_FILE-clean.xml

echo '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
  &lt;?xml version="1.0" encoding="UTF-8"?&gt;
  &lt;osm version="0.6" generator="madridxml2osm.sh"&gt;

      <xsl:for-each select="catalogo/contenido">
    &lt;node id="<xsl:value-of select="ID-ENTIDAD"/>" lat="<xsl:value-of select="LATITUD"/>" lon="<xsl:value-of select="LONGITUD"/>" &gt;
        &lt;tag k="'$LLAVE'" v="'$VALOR'"/&gt;
        &lt;tag k="name" v="<xsl:value-of select="NOMBRE"/>"/&gt;
        &lt;tag k="description" v="<xsl:value-of select="DESCRIPCION"/> <xsl:value-of select="DESCRIPCION-ENTIDAD"/> <xsl:value-of select="EQUIPAMIENTO"/>"/&gt;
        &lt;tag k="opening_hours" v="<xsl:value-of select="HORARIO"/>"/&gt;
        &lt;tag k="phone" v="+34 <xsl:value-of select="TELEFONO"/>"/&gt;
        &lt;tag k="fax" v="+34 <xsl:value-of select="FAX"/>"/&gt;
        &lt;tag k="addr:street" v="<xsl:value-of select="CLASE-VIAL"/><xsl:text> FIXME </xsl:text><xsl:value-of select="NOMBRE-VIA"/>"/&gt;
        &lt;tag k="addr:housenumber" v="<xsl:value-of select="NUM"/>"/&gt;
        &lt;tag k="addr:postcode" v="<xsl:value-of select="CODIGO-POSTAL"/>"/&gt;
        &lt;tag k="wheelchair" v="<xsl:value-of select="ACCESIBILIDAD"/>"/&gt;
        &lt;tag k="url" v="<xsl:value-of select="CONTENT-URL"/>"/&gt;
        &lt;tag k="email" v="<xsl:value-of select="EMAIL"/>"/&gt;
        &lt;tag k="source" v="Ayuntamiento de Madrid"/&gt;
    &lt;/node&gt;

</xsl:for-each>
</xsl:template>
</xsl:stylesheet>

' > $OUT_FILE.xsl

# Procesado del xsl y xml limpio
rm -f $OUT_FILE.osm
xsltproc $OUT_FILE.xsl $OUT_FILE-clean.xml  > $OUT_FILE.osm

echo "</osm>" >> $OUT_FILE.osm

grep -v '" v="&' $OUT_FILE.osm | grep -v '" v="+34 &' | perl -pe 's/&lt;/</g' | perl -pe 's/&gt;/>/g' | grep -v '""' | sed '0,/<?xml version="1.0"?>/s///' | perl -pe 's/  <\?/<\?/g' | sed '/^\s*$/d' > /tmp/foo ; mv /tmp/foo $OUT_FILE.osm


# no fax or phone fix
grep -v 'tag k="fax" v="+34 "/>' $OUT_FILE.osm | grep -v 'tag k="phone" v="+34 "/>' > /tmp/foo ; mv /tmp/foo $OUT_FILE.osm

# wheelchair fix
perl -pe 's/tag k="wheelchair" v="1"\/>/tag k="wheelchair" v="yes"\/>/g' $OUT_FILE.osm | perl -pe 's/tag k="wheelchair" v="0"\/>/tag k="wheelchair" v="no"\/>/g' > /tmp/foo ; mv /tmp/foo $OUT_FILE.osm

# space and nodes without coordinates fix
perl -pe 's/v=" /v="/g' $OUT_FILE.osm | perl -pe 's/        //g' | perl -pe 's/       //g' | perl -pe 's/      //g' | perl -pe 's/     //g' | perl -pe 's/    //g' | perl -pe 's/   //g' | perl -pe 's/  / /g' | perl -pe 's/\n//g' | perl -pe 's/\/node>/\/node>\n/g' | grep 'lon=' | perl -pe 's/>/>\n/g' | sed '/^\s*$/d' | perl -pe 's/\n /\n/g' | perl -pe 's/. "/."/g' | perl -pe 's/ ."/."/g' > /tmp/foo ; mv /tmp/foo $OUT_FILE.osm

echo "</osm>" >> $OUT_FILE.osm


while IFS='' read -r line || [[ -n "$line" ]]; do
# corregir capitalización de lugares
  if echo $line | grep --quiet "addr:" ; then
    LUGAR=`echo $line | awk -F '"' '{print $4}'`
    LUGAR_CAPITALIZADO=`echo "${LUGAR,,}" | sed -e "s/\b\(.\)/\u\1/g" | perl -pe 's/Fixme/FIXME/g'`
    echo $line | perl -pe "s/$LUGAR/$LUGAR_CAPITALIZADO/g" >> $OUT_FILE-clean.osm
  else
# Formato de números de teléfono y fax. Nos quedamos con el primer número.
    if echo $line | grep --quiet 'v="+34' ; then
      echo $line | tr -d ' '  | sed -n 's/\+349[0-9]\{8\}/&XX/p' | perl -pe 's/XX/"\/>\n/g' | grep 'k=' | perl -pe 's/<tagk/<tag k/g' | perl -pe 's/\+34/\+34 /g' | perl -pe 's/v=/ v=/g'>> $OUT_FILE-clean.osm
    else
# fix ampersand en las URLs
      if echo $line | grep --quiet 'k="url"' ; then
        echo $line | perl -pe 's/--FIXME--/&/g' >> $OUT_FILE-clean.osm
      else
        echo $line >> $OUT_FILE-clean.osm
      fi
    fi
  fi

done < $OUT_FILE.osm

# tabulation
perl -pe 's/<tag/    <tag/g' $OUT_FILE-clean.osm | perl -pe 's/<node/  <node/g' | perl -pe 's/<\/node>/  <\/node>/g' >  $OUT_FILE.osm

# fix headers if absent
if head -n1 $OUT_FILE.osm | grep --quiet "node" ; then
 cp $OUT_FILE.osm /tmp/foo
 echo '<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="madridxml2osm.sh">' > $OUT_FILE.osm
 cat /tmp/foo >> $OUT_FILE.osm
fi

# listado y stats
grep 'k="name"' $OUT_FILE.osm | awk -F '"' '{print $4}' > puntos ; cat puntos ; wc -l puntos ; rm puntos

rm $OUT_FILE-clean.osm $OUT_FILE.xsl $OUT_FILE-clean.xml
exit 0
