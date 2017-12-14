#!/bin/bash
#
# snake
#
# v2.0
#
# Author: various
#Last edit from: matteolocci at live dot it 2017
#
# Functions

drawborder() {
   # Bordo superiore
   tput setf 6
   tput cup $FIRSTROW $FIRSTCOL
   x=$FIRSTCOL
   while [ "$x" -le "$LASTCOL" ];
   do
      printf %b "$WALLCHAR"
      x=$(( $x + 1 ));
   done

   # lati
   x=$FIRSTROW
   while [ "$x" -le "$LASTROW" ];
   do
      tput cup $x $FIRSTCOL; printf %b "$WALLCHAR"
      tput cup $x $LASTCOL; printf %b "$WALLCHAR"
      x=$(( $x + 1 ));
   done

   # footer finestra
   tput cup $LASTROW $FIRSTCOL
   x=$FIRSTCOL
   while [ "$x" -le "$LASTCOL" ];
   do
      printf %b "$WALLCHAR"
      x=$(( $x + 1 ));
   done
   tput setf 9
}

apple() {
   # Recupera le coordinate dell'area di lavoro
   APPLEX=$[( $RANDOM % ( $[ $AREAMAXX - $AREAMINX ] + 1 ) ) + $AREAMINX ]
   APPLEY=$[( $RANDOM % ( $[ $AREAMAXY - $AREAMINY ] + 1 ) ) + $AREAMINY ]
}

drawapple() {
   # Verifica quando lo spazio è occupato
   LASTEL=$(( ${#LASTPOSX[@]} - 1 ))
   x=0
   apple
   while [ "$x" -le "$LASTEL" ];
   do
      if [ "$APPLEX" = "${LASTPOSX[$x]}" ] && [ "$APPLEY" = "${LASTPOSY[$x]}" ];
      then
         # Posizione non valida
         x=0
         apple
      else
         x=$(( $x + 1 ))
      fi
   done
   tput setf 4
   tput cup $APPLEY $APPLEX
   printf %b "$APPLECHAR"
   tput setf 9
}

growsnake() {
   # puntatore di posizione
   LASTPOSX=( ${LASTPOSX[0]} ${LASTPOSX[0]} ${LASTPOSX[0]} ${LASTPOSX[@]} )
   LASTPOSY=( ${LASTPOSY[0]} ${LASTPOSY[0]} ${LASTPOSY[0]} ${LASTPOSY[@]} )
   RET=1
   while [ "$RET" -eq "1" ];
   do
      apple
      RET=$?
   done
   drawapple
}

move() {
   case "$DIRECTION" in
      u) POSY=$(( $POSY - 1 ));;
      d) POSY=$(( $POSY + 1 ));;
      l) POSX=$(( $POSX - 1 ));;
      r) POSX=$(( $POSX + 1 ));;
   esac

   # verifica collisioni
   ( sleep $DELAY && kill -ALRM $$ ) &
   if [ "$POSX" -le "$FIRSTCOL" ] || [ "$POSX" -ge "$LASTCOL" ] ; then
      tput cup $(( $LASTROW + 1 )) 0
      stty echo
      echo " GAME OVER! Schianto!"
      gameover
   elif [ "$POSY" -le "$FIRSTROW" ] || [ "$POSY" -ge "$LASTROW" ] ; then
      tput cup $(( $LASTROW + 1 )) 0
      stty echo
      echo " GAME OVER! Schianto!"
      gameover
   fi

   # Recupera il valore del vettore
   LASTEL=$(( ${#LASTPOSX[@]} - 1 ))
   #tput cup $ROWS 0
   #printf "LASTEL: $LASTEL"

   x=1 # Imposta elemento di avvio ad 1 sulla posizione 0 lontano dalla coda
   while [ "$x" -le "$LASTEL" ];
   do
      if [ "$POSX" = "${LASTPOSX[$x]}" ] && [ "$POSY" = "${LASTPOSY[$x]}" ];
      then
         tput cup $(( $LASTROW + 1 )) 0
         echo " GAME OVER! AutoSchianto!"
         gameover
      fi
      x=$(( $x + 1 ))
   done

   # pulisce le posizioni a schermo
   tput cup ${LASTPOSY[0]} ${LASTPOSX[0]}
   printf " "

   # Sfondatore
   LASTPOSX=( `echo "${LASTPOSX[@]}" | cut -d " " -f 2-` $POSX )
   LASTPOSY=( `echo "${LASTPOSY[@]}" | cut -d " " -f 2-` $POSY )
   tput cup 1 10
   #echo "LASTPOSX array ${LASTPOSX[@]} LASTPOSY array ${LASTPOSY[@]}"
   tput cup 2 10
   echo "LUNG=${#LASTPOSX[@]}"

   # Aggiorna posizioni sul valore più alto
   LASTPOSX[$LASTEL]=$POSX
   LASTPOSY[$LASTEL]=$POSY

   # Genera nuova posizione
   tput setf 2
   tput cup $POSY $POSX
   printf %b "$SNAKECHAR"
   tput setf 9

   # verifica collisione
   if [ "$POSX" -eq "$APPLEX" ] && [ "$POSY" -eq "$APPLEY" ]; then
      growsnake
      updatescore 10
   fi
}

updatescore() {
   SCORE=$(( $SCORE + $1 ))
   tput cup 2 30
   printf "PUN: $SCORE"
}
randomchar() {
    [ $# -eq 0 ] && return 1
    n=$(( ($RANDOM % $#) + 1 ))
    eval DIRECTION=\${$n}
}

gameover() {
   tput cvvis
   stty echo
   sleep $DELAY
   trap exit ALRM
   tput cup $ROWS 0
   exit
}

#SNAKECHAR="\0256"                      # Carattere del serpente
#WALLCHAR="\0244"                       # Carattere delle pareti
#APPLECHAR="\0362"                      # Carattere per punto
#
# Caratteri ASCII
SNAKECHAR="@"                           # Carattere del serpente
WALLCHAR="X"                            # Carattere delle pareti
APPLECHAR="o"                           # Carattere per punto
#
SNAKESIZE=3                             # Dimmensione iniziale 
DELAY=0.2                               # Delay movimento
FIRSTROW=3                              # Prima riga area di gioco
FIRSTCOL=1                              # Prima colonna area di gioco
LASTCOL=40                              # Ultima colonna area di gioco
LASTROW=20                              # Ultima riga area di gioco
AREAMAXX=$(( $LASTCOL - 1 ))            # Punto più lontano asse x destra
AREAMINX=$(( $FIRSTCOL + 1 ))           # Punto più lontano asse x sinistra
AREAMAXY=$(( $LASTROW - 1 ))            # Punto più basso assey y
AREAMINY=$(( $FIRSTROW + 1))            # Punto più alto asse y
ROWS=`tput lines`                       # Numero di righe terminale
ORIGINX=$(( $LASTCOL / 2 ))             # Start X - usa bc 
ORIGINY=$(( $LASTROW / 2 ))             # Start Y - usa bc
POSX=$ORIGINX                           # Set POSX per posizione di partenza
POSY=$ORIGINY                           # Set POSY per posizione di partenza

# Area vettori
ZEROES=`echo |awk '{printf("%0"'"$SNAKESIZE"'"d\n",$1)}' | sed 's/0/0 /g'`
LASTPOSX=( $ZEROES )                    # Imposta vettore a 0
LASTPOSY=( $ZEROES )                    # Imposta vettore a 0

SCORE=0                                 # Punteggio di partenza

clear
# Stampa istruzioni
echo "
Tasti:

 W - Su
 S - Giu'
 A - Sinistra
 D - Destra
 X - Esci

Modificare le varibili se ci sono problemi in vista
SNAKECHAR, APPLECHAR e WALLCHAR.


Premi invio per continuare
"

stty -echo
tput civis
read RTN
tput setb 0
tput bold
clear
drawborder
updatescore 0

# Stampa prima o
# (Esegue controllo collisione per non farla apparire sul serpente)
drawapple
sleep 1
trap move ALRM

# Prende direzione random all'avvio
DIRECTIONS=( u d l r )
randomchar "${DIRECTIONS[@]}"

sleep 1
move
while :
do
   read -s -n 1 key
   case "$key" in
   w)   DIRECTION="u";;
   s)   DIRECTION="d";;
   a)   DIRECTION="l";;
   d)   DIRECTION="r";;
   x)   tput cup $COLS 0
        echo "Esco..."
        tput cvvis
        stty echo
        tput reset
        printf "CIA!\n"
        trap exit ALRM
        sleep $DELAY
        exit 0
        ;;
   esac
done
