#!/bin/bash

  PDF="$1"

  TMPDIR="."
   TMPID="$TMPDIR/tmp"

  YOURLSCONFIG="../lib/yourls.config"
  SHORTURLBASE=`grep "^SHORTURLBASE" $YOURLSCONFIG | #
                tail -n 1 | cut -d ":" -f 2-`
     YOURLSAPI=`grep "^API" $YOURLSCONFIG | #
                tail -n 1 | cut -d ":" -f 2-`
     YOURLSSIG=`grep "^SIGNATURE" $YOURLSCONFIG | #
                tail -n 1 | cut -d ":" -f 2-`

  PREVIEWSIZE="800";OPACITY="0.3"
  CANVASPDF="../lib/pdf/canvas.pdf"

  OUTID=`md5sum $PDF| cut -c 1-8`
  if [ ! -d "$OUTID" ];then mkdir $OUTID;fi
  OUTID="$OUTID/$OUTID"
   HTML="${OUTID}.html"
  MAPTMP="$TMPID.map"

# --------------------------------------------------------------------------- #
# GENERATE TWO PAGED PREVIEW
# --------------------------------------------------------------------------- #

  if [ `ls ${OUTID}_*.png | wc -l` -lt 1 ];then

  # TODO: generate canvas.pdf, start odd page on the right

  echo "\documentclass[9pt]{scrbook}"                    >  ${TMPID}.tex
  echo "\usepackage{pdfpages}"                           >> ${TMPID}.tex
  echo "\usepackage{geometry}"                           >> ${TMPID}.tex
 #echo "\geometry{paperwidth=840pt,paperheight=590pt}"   >> ${TMPID}.tex
 #echo "\geometry{paperwidth=4200pt,paperheight=2950pt}" >> ${TMPID}.tex
 #echo "\geometry{paperwidth=6300pt,paperheight=4425pt}" >> ${TMPID}.tex
  echo "\geometry{paperwidth=8400pt,paperheight=5900pt}" >> ${TMPID}.tex
  echo "\begin{document}"                                >> ${TMPID}.tex
  echo "\includepdf[delta=10 0,scale=.95,"               >> ${TMPID}.tex
  echo "            pages=-,nup=2x1,frame=false]"        >> ${TMPID}.tex
  echo "{"${PDF}"}"                                      >> ${TMPID}.tex
  echo "\end{document}"                                  >> ${TMPID}.tex

  pdflatex -interaction=nonstopmode \
           -output-directory $TMPDIR \
            ${TMPID}.tex #  > /dev/null
  pdftk ${TMPID}.pdf background $CANVASPDF output ${TMPID}2.pdf

  convert ${TMPID}2.pdf ${OUTID}_%04d.png

  fi

# --------------------------------------------------------------------------- #
# WRITE HTML HEADER
# --------------------------------------------------------------------------- #

  echo '<html><head>'                                                >  $HTML

  echo '<style>'                                                     >> $HTML

  echo 'body { padding:0;margin:0;'                                  >> $HTML
  echo '       padding-bottom:10%;'                                  >> $HTML
  echo '       background-color:#fefefe; }'                          >> $HTML
  echo 'span,form{ font-size:12px;'                                  >> $HTML
  echo '           font-family:monospace;'                           >> $HTML
  echo '           line-height:1.5em;'                               >> $HTML
  echo '           margin-bottom: 5px;}'                             >> $HTML
  echo 'form { font-size:20px; }'                                    >> $HTML
  echo '.s { float:left;'                                            >> $HTML
  echo '     white-space: nowrap;'                                   >> $HTML
  echo '     font-size:.7em;'                                        >> $HTML
  echo '     line-height:1.8em;'                                     >> $HTML
  echo '     clear:both; }'                                          >> $HTML
  echo '.s  > a { text-decoration:none;'                             >> $HTML
  echo '          margin:-4px 4px -4px -4px;'                        >> $HTML
  echo '          padding: 4px 4px 4px 4px;'                         >> $HTML
  echo '          color: #ffffff; }'                                 >> $HTML
  echo '.s  > a:hover { background-color:none;'                      >> $HTML
  echo '                color: #ff0000;}'                            >> $HTML
  echo '.unset  > form > input,'                                     >> $HTML
  echo '.unset > .s  > a { font-size:16px;'                          >> $HTML
  echo '                   background-color:#ffffff; }'              >> $HTML
  echo '.isset  > form > input,'                                     >> $HTML
  echo '.isset > .s  > a { background-color:#00ff00; }'              >> $HTML
  echo 'img,div.isset,div.unset{ position:relative;'                 >> $HTML
  echo '                         float:left;'                        >> $HTML
  echo '                         margin:0;}'                         >> $HTML
  echo 'img { width:75%;z-index:3; }'                                >> $HTML
  echo 'div.isset,div.unset{ padding:2.5%; }'                        >> $HTML
  echo 'div.isset { width:21%;height:200px;'                         >> $HTML
  echo '            z-index:2;'                                      >> $HTML
  echo '            background-color:transparent;'                   >> $HTML
  echo '            margin-top:2%;margin-right:-1%;}'                >> $HTML
  echo 'div.unset { float:right;width:70%;height:200px;'             >> $HTML
  echo '            z-index:1;'                                      >> $HTML
  echo '            background-color:#eeeeee;'                       >> $HTML
  echo '            padding-left:30%;'                               >> $HTML
  echo '            margin-bottom:15vw;margin-top:0%;'               >> $HTML
  echo '            clear:both; }'                                   >> $HTML
  echo '.lock,.lock > a { background-color:#ff0000!important; }'     >> $HTML
  echo '.highlight,'                                                 >> $HTML
  echo '.highlight > a { background-color:#000000!important; }'      >> $HTML

  echo '</style>'                                                    >> $HTML

  echo '<script src="../../lib/js/jquery-3.3.1.js"></script>'        >> $HTML
  echo '</head><body>'                                               >> $HTML

# --------------------------------------------------------------------------- #
# ANALYSE BOOK PAGES
# --------------------------------------------------------------------------- #
  for ANALYSETHIS in `ls ${OUTID}*.png`
   do
       IINFO=`identify -format "%wx%h" "$ANALYSETHIS"[0]`
          IW=`echo $IINFO | cut -d "x" -f 1`
          IH=`echo $IINFO | cut -d "x" -f 2`
       SCALEFACTOR=`python -c "print ${IW}.0 / $PREVIEWSIZE"`
 
     ZBAR=`echo "from sys import argv
                 import zbar
                 import Image
                 # create a reader
                 scanner = zbar.ImageScanner()
                 # configure the reader
                 scanner.parse_config('enable')
                 # obtain image data
                 pil = Image.open(\"$ANALYSETHIS\").convert('L')
                 width, height = pil.size
                 raw = pil.tostring()
                 # wrap image data
                 image = zbar.Image(width,height,'Y800',raw)
                 # scan the image for barcodes
                 scanner.scan(image)
                 # extract results
                 for symbol in image:
                     # do something useful with results
                     print 'decoded',symbol.type,'"%s"'%symbol.data
                     tl, bl, br, tr = [item for item in symbol.location]
                     print tl,tr,br,bl
                 # clean up
                 del(image)"            | # THIS IS THE PYTHON CODE
           sed 's/^                 //' | # CORRECT INDENTATION
           python`                        # RUN PYTHON CODE
 
      MAPNAME=`echo $ANALYSETHIS | md5sum | cut -c 1-16`
      IMAGEID=`echo $MAPNAME | rev`; # echo $IMAGEID
      PREVIEW=`echo $ANALYSETHIS | sed 's/\.png$//'`.gif
      PREVIEWMARKED=`echo $ANALYSETHIS | sed 's/\.png$//'`_marked.gif
      convert $ANALYSETHIS -resize $PREVIEWSIZE $PREVIEW
  
      if [ `echo $ZBAR | wc -c` -gt 1 ]; then
            echo "<map name=\"$MAPNAME\">"                   >> $MAPTMP
            MAP="YES"
       else MAP="NO"
      fi
    # ----------------------------------------------------------------- #
      CNT="1";COLORTAKEN="XXXX";DRAW="" # RESET

      for BARCODE in `echo $ZBAR          | #
                      sed 's/ //g'        | #
                      sed 's/decoded/\n/g'| #
                      sort -n -t '(' -k 2`  #
        do
            URL=`echo "$BARCODE"         | #
                 cut -d "(" -f 1         | #
                 sed 's/QRCODE//'`         #
            SHORTURLCHECK=`echo "$SHORTURLBASE"         | #
                           tr [:upper:] [:lower:]       | #
                           sed 's/http[s]*/http.\\\\?/g'` #

            if [ `echo "$URL" | #
                  grep -i "$SHORTURLCHECK"  | #
                  wc -l` -lt 1 ]
            then  MATCHSHORTURL="NO"
            else  MATCHSHORTURL="YES"
            fi

             CHECK=`curl -sIL $URL          | #
                    tr -d '\015'            | #
                    grep ^Location          | #
                    tail -n 1               | #
                    grep -v "$SHORTURLBASE" | #
                    wc -c`                    #
              SHORTURL=`echo $URL           | #
                        rev                 | #
                        cut -d "/" -f 1     | #
                        rev`                  #

              URLID=URL`echo $SHORTURL      | #
                        md5sum              | #
                        sed 's/[a-f]//g'    | #
                        cut -c 1-8`ID         #
              THISID=`echo $RANDOM          | #
                      md5sum | cut -c 1-8`    #
               MAPID=`echo $THISID | rev`
              XY=`echo "$BARCODE"           | #
                  cut -d "(" -f 2-          | #
                  sed 's/)(/,/g'            | #
                  sed 's/[()]//g'`            #  
        
    # ----------------------------------------------------------------------- #
      if [ $CHECK -gt 1 ]; then
  
           COLOR="00ff00";OPACITY="0.1"
           echo "<span class=\"s\" id=\"$THISID\">"           >> $TMPID.isset
           echo "<a href=\"$URL\">$URL</a> "                  >> $TMPID.isset
           echo "</span>"                                     >> $TMPID.isset

      else

          COLOR="ff0000";OPACITY="0.3"

          if [ "$MATCHSHORTURL" == "YES" ];then

         # echo "$URL needs to be defined"
           echo "<form action=\"$SHORTURLBASE/$YOURLSAPI\">"  >> $TMPID.unset
           echo "<input type=\"hidden\""                      >> $TMPID.unset
           echo " name=\"signature\" value=\"$YOURLSSIG\">"   >> $TMPID.unset
           echo "<input type=\"hidden\""                      >> $TMPID.unset
           echo " name=\"action\" value=\"shorturl\">"        >> $TMPID.unset
           echo "<input type=\"hidden\" name=\"keyword\""     >> $TMPID.unset
           echo " value=\"$SHORTURL\">"                       >> $TMPID.unset
           echo "<input type=\"text\" id=\"$THISID\""         >> $TMPID.unset
           echo "name=\"url\" placeholder=\"url\">"           >> $TMPID.unset
           echo "<input type=\"submit\" value=\"make link\">" >> $TMPID.unset
           echo "</form>"                                     >> $TMPID.unset

          else

           echo "<span class=\"s\">"                          >> $TMPID.unset
           echo "<a href=\"#$MAPID\">$URL UNDEFINED</a> "     >> $TMPID.unset
           echo "</span>"                                     >> $TMPID.unset

          fi
  
          URL="#$THISID"

      fi
    # ----------------------------------------------------------------------- #

             ALLURLS="$ALLURLS|$URL,$URLID,$IMAGEID"
  
           # COPY AND MARK COORDINATES
           # -------------------------
             XYNEW=`echo $XY | sed 's/,/,\n/g'     | #
                    awk '{printf "%d:%s\n",NR,$0}' | #
                    sed ':a;N;$!ba;s/\n//g'`         #
  
           # echo "XYNEW: $XYNEW"
   
           # SCALE COORDINATES
           # -----------------
             for V in `echo $XYNEW   | #
                       sed 's/,/ /g' | #
                       tee`
              do
                 VMARK=`echo $V | cut -d ":" -f 1`
                 VALUE=`echo $V | cut -d ":" -f 2`
                  VNEW=`python -c "print $VALUE / $SCALEFACTOR" | #
                        cut -d "." -f 1`
                 XYNEW=`echo $XYNEW      | #
                        sed "s/$V/$VNEW/g"`
             done
   
           # DRAW COMMAND FOR IMAGEMAGICK
           # ----------------------------
             POLYGON=`echo $XYNEW | #
                      sed -e 's/\(\([^,]*,\)\{1\}[^,]*\),/\1 /g'`
             DRAW="$DRAW -draw \"fill #$COLOR  \
                                 stroke #$COLOR \
                                 fill-opacity $OPACITY  \
                                 stroke-opacity $OPACITY \
                                 polygon $POLYGON\""
           # HTML MAP 
           # ----------------------------
             echo "<area shape=\"poly\" 
                    coords=\"$XYNEW\" 
                    href=\"javascript:void(0)\" 
                    data-tid=\"$THISID\" 
                    class=\"map\">" | tr -s ' ' >> $MAPTMP

           CNT=`expr $CNT + 1`
      done
  
      if [ X$MAP == XYES ]; then
           echo "</map>" >> $MAPTMP
      fi
  
     # ----------------------------------------------------------------- #
       DRAW=`echo $DRAW | sed ':a;N;$!ba;s/\n/ /g' | tr -s ' '`
       eval "convert $PREVIEW -strokewidth 10 $DRAW $PREVIEWMARKED"

     # ----------------------------------------------------------------- #
       echo '<div class="isset urlinfo">'                       >> $HTML
       if [ -f "$TMPID.isset" ];then 
       cat $TMPID.isset                                         >> $HTML
       rm $TMPID.isset;fi
       echo '</div>'                                            >> $HTML
     # ----------------------------------------------------------------- #
       echo "<img src=\"`basename $PREVIEWMARKED`\" id=\"$IMAGEID\" 
              usemap=\"#$MAPNAME\">" | tr -s ' '                >> $HTML
     # ----------------------------------------------------------------- #
       echo '<div class="unset urlinfo">'                       >> $HTML
       if [ -f "$TMPID.unset" ];then 
       cat $TMPID.unset                                         >> $HTML
       rm $TMPID.unset;fi
       echo '</div>'                                            >> $HTML
     # ----------------------------------------------------------------- #

  done
 
  cat $MAPTMP                                                        >> $HTML
  echo '<script type="text/javascript"'                              >> $HTML
  echo 'src="../../lib/js/imageMapResizer.js"></script>'             >> $HTML
  echo '<script type="text/javascript">imageMapResize();</script>'   >> $HTML

  echo '<script type="text/javascript">'                             >> $HTML
  echo '$(document).ready(function() {'                              >> $HTML
  echo '        $( ".map" ).hover('                                  >> $HTML
  echo '          function() { // OVER'                              >> $HTML
  echo '            tid = $( this ).data("tid");'                    >> $HTML
  echo '            $( "#" + tid ).addClass( "highlight" );'         >> $HTML
  echo '          },'                                                >> $HTML
  echo '          function() { // OUT'                               >> $HTML
  echo '            tid = $( this ).data("tid");'                    >> $HTML
  echo '            $( "#" + tid ).removeClass( "highlight" );'      >> $HTML
  echo '          }'                                                 >> $HTML
  echo '        );'                                                  >> $HTML
  echo '      $( ".map" ).click('                                    >> $HTML
  echo '       function() {'                                         >> $HTML
  echo '         $(".urlinfo").each(function() {'                    >> $HTML
  echo '         $(this).children().removeClass("lock");'            >> $HTML
  echo '         $(this).children().children().removeClass("lock");' >> $HTML
  echo '        });'                                                 >> $HTML
  echo '        tid = $( this ).data("tid");'                        >> $HTML
  echo '        $( "#" + tid ).addClass( "lock" );'                  >> $HTML
  echo '        $( "#" + tid ).removeClass( "highlight" );'          >> $HTML
  echo '       }'                                                    >> $HTML
  echo '      );'                                                    >> $HTML
  echo '});'                                                         >> $HTML
  echo '</script>'                                                   >> $HTML

  echo "</body></html>"                                              >> $HTML

# --------------------------------------------------------------------------- #
# CLEAN UP
# --------------------------------------------------------------------------- #
  if [ `echo ${TMPID} | wc -c` -ge 4 ] &&
     [ `ls ${TMPID}*.* 2>/dev/null | wc -l` -gt 0 ]
  then  rm ${TMPID}*.* ;fi

exit 0;


