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
  COLORSET="44aa00;ff0000;003380;ffcc00;55ddff;ad60f2;ff00cc;aaffcc;
            44aa00;ff0000;003380;ffcc00;55ddff;ad60f2;ff00cc;aaffcc;
            44aa00;ff0000;003380;ffcc00;55ddff;ad60f2;ff00cc;aaffcc;
            44aa00;ff0000;003380;ffcc00;55ddff;ad60f2;ff00cc;aaffcc;"
  COLORSET=`echo $COLORSET | sed ":a;N;\$!ba;s/\n//g" | sed 's/ //g'`
  COLORSET=`printf "$COLORSET%.0s" {1..100}`

  MAPTMP="$TMPID.map"

  OUTID=`md5sum $PDF| cut -c 1-8`
  if [ ! -d "$OUTID" ];then mkdir $OUTID;fi
  OUTID="$OUTID/$OUTID"
   HTML="${OUTID}.html"

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
  echo 'body { padding-bottom:10%;}'                                 >> $HTML
  echo 'span,form{ font-size:12px;'                                  >> $HTML
  echo '           font-family:monospace;'                           >> $HTML
  echo '           line-height:1.5em;'                               >> $HTML
  echo '           margin-left:25px;'                                >> $HTML
  echo '           margin-bottom: 5px;}'                             >> $HTML
  echo 'form { padding:4px 4px 4px 4px;}'                            >> $HTML
  echo 'img { margin-top:50px; }'                                    >> $HTML
  echo '.s { margin-left:30px;'                                      >> $HTML
  echo '     font-size:.7em;'                                        >> $HTML
  echo '     line-height:2em;}'                                      >> $HTML
  echo '.s  > a { text-decoration:none;'                             >> $HTML
  echo '          margin:-4px 4px -4px -4px;'                        >> $HTML
  echo '          padding: 4px 4px 4px 4px;'                         >> $HTML
  echo '          color: #ffffff;}'                                  >> $HTML
  echo '.s  > a:hover { background-color:none;'                      >> $HTML
  echo '                color: #ff0000;}'                            >> $HTML

  for COLOR in `echo $COLORSET | sed 's/;/\n/g'`
   do COLORID=`echo $COLOR | base64 | sed 's/[^a-zA-Z]*//g'`
      echo ".$COLORID {"                                             >> $HTML
      echo "   color:#$COLOR;"                                       >> $HTML
      echo "}"                                                       >> $HTML
      echo ".$COLORID  > form > input,"                              >> $HTML
      echo ".$COLORID > .s  > a {"                                   >> $HTML
      echo "   background-color:#$COLOR;"                            >> $HTML
      echo "}"                                                       >> $HTML
  done

  echo '</style>'                                                    >> $HTML
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
  
      echo "<img src=\"`basename $PREVIEWMARKED`\" id=\"$IMAGEID\" 
             usemap=\"#$MAPNAME\"><br/>" | tr -s ' '         >> $HTML

      if [ `echo $ZBAR | wc -c` -gt 1 ]; then
            echo "<map name=\"$MAPNAME\">"                   >> $MAPTMP
            MAP="YES"
       else MAP="NO"
      fi
    # ----------------------------------------------------------------- #
      CNT="1";COLORTAKEN="XXXX";DRAW="" # RESET

      for BARCODE in `echo $ZBAR          | #
                      sed 's/ //g'        | #
                      sed 's/decoded/\n/g'` #
        do
            URL=`echo "$BARCODE"         | #
                 cut -d "(" -f 1         | #
                 sed 's/QRCODE//'`         #

            if [ `echo $URL | grep -i "$SHORTURLBASE" | #
                  wc -l` -lt 1 ]
            then
                  echo "NOT A MATCHING SHORTURL"

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

              COLOR=`echo $COLORSET          | #
                     sed 's/;/\n/g'          | #
                     head -n $CNT | tail -n 1`

              COLORID=`echo $COLOR | base64 | sed 's/[^a-zA-Z]*//g'`

              echo "<span class=\"$COLORID\">" >> $HTML

        
           # ----------------------------------------------------------------- #
             if [ $CHECK -gt 1 ]; then
  
                 echo "<span class=\"s\" id=\"$THISID\">"            >> $HTML
                 echo "<a href=\"$URL\">$URL</a> "                   >> $HTML
                 echo " already defined "                            >> $HTML
                 echo "<a href=\"#$MAPID\">M</a><br/>"               >> $HTML
                 echo "</span>"                                      >> $HTML

             else
  
             if [ `echo $ALLURLS | grep $URL | wc -l` -gt 0 ];
              then
                  echo "<span class=\"s\">"                          >> $HTML
                # echo "$URLID $IMAGEID $URL"
                  echo "$URLID $IMAGEID"                             >> $HTML
                  echo "</span>"                                     >> $HTML
               else
                  echo "<form action=\"$SHORTURLBASE/$YOURLSAPI\">"  >> $HTML
                # echo "$URL needs to be defined"
                  echo "<input type=\"hidden\""                      >> $HTML
                  echo " name=\"signature\" value=\"$YOURLSSIG\">"   >> $HTML
                  echo "<input type=\"hidden\""                      >> $HTML
                  echo " name=\"action\" value=\"shorturl\">"        >> $HTML
                  echo "<input type=\"hidden\" name=\"keyword\""     >> $HTML
                  echo " value=\"$SHORTURL\">"                       >> $HTML
                  echo "<input type=\"text\" id=\"$THISID\""         >> $HTML
                  echo "name=\"url\" placeholder=\"url\">"           >> $HTML
                  echo "<input type=\"submit\" value=\"make link\">" >> $HTML
                  echo "</form>"                                     >> $HTML
  
                  echo "<span class=\"s\">"                          >> $HTML
                # echo "$URLID $IMAGEID $URL"
                  echo "$URLID $IMAGEID XX"                          >> $HTML
                  echo "<br/></span>"                                >> $HTML

                  #URL="#$THISID"
              fi
             fi
             echo "<br/></span>"                                     >> $HTML
           # ----------------------------------------------------------------- #

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
                  VNEW=`python -c "print $VALUE / $SCALEFACTOR"`
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
                     href=\"$URL\" 
                     id=\"$MAPID\">" | tr -s ' ' >> $MAPTMP

           CNT=`expr $CNT + 1`
      done
  
      if [ X$MAP == XYES ]; then
           echo "</map>" >> $MAPTMP
      fi
  
     # ----------------------------------------------------------------- #
       DRAW=`echo $DRAW | sed ':a;N;$!ba;s/\n/ /g' | tr -s ' '`
       eval "convert $PREVIEW -strokewidth 10 $DRAW $PREVIEWMARKED"
  
  done
 
  cat $MAPTMP           >> $HTML
  echo "</body></html>" >> $HTML

# --------------------------------------------------------------------------- #
# FINALISE HTML
# --------------------------------------------------------------------------- #
  for URLID in `echo $ALLURLS   | #
                sed "s,|,\n&,g" | #
                tee`              #
   do
      URLID=`echo $URLID | cut -d "," -f 2`

      for URLID in `grep $URLID $HTML | #
                    sed 's/ /_/g'     | #
                    uniq`
       do
           URLID=`echo $URLID | sed 's/_/ /g'`
           IMGID=`echo $URLID | cut -d " " -f 2`
           URLID=`echo $URLID | cut -d " " -f 1`
 
           WHERE=`echo $ALLURLS        | #
                  sed "s,$URLID,\n&,g" | #
                  cut -d "|" -f   1    | #
                  grep ^$URLID         | #
                  grep -v $IMGID       | #
                  cut -d "," -f 2      | #
                  sed 's/.*/<a href=\"#&\">O<\\\\\/a> /' | #
                  sed ':a;N;$!ba;s/\n/ /g'` #
 
           if [ `echo $WHERE | wc -c` -gt 2 ]; then
           sed -i "/$IMGID/s/$URLID/$WHERE/g" $HTML
           sed -i "/$WHERE/s/$IMGID//g"       $HTML
           fi
      done
  done

  # REMOVE REMAINING URLIDS
  sed -i "s/URL[0-9]*ID//g" $HTML
  sed -i "/XX$/s/ [a-f0-9]\{16\} //g" $HTML
  sed -i "s/XX//g" $HTML

# --------------------------------------------------------------------------- #
# CLEAN UP
# --------------------------------------------------------------------------- #
  if [ `echo ${TMPID} | wc -c` -ge 4 ] &&
     [ `ls ${TMPID}*.* 2>/dev/null | wc -l` -gt 0 ]
  then  rm ${TMPID}*.* ;fi

exit 0;


