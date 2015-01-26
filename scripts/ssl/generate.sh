#!/bin/bash
#
# Lag priv cert, og generer signing request

dir=$(cd $(dirname $0) ; pwd)
cd $dir

lag_req() {
	server=$1
	mkdir -p $dir/kunder/$server
	openssl req -config ./req.cfg -newkey rsa:2048 -nodes -keyout kunder/$server/$server.key -out kunder/$server/$server.csr
	chmod 600 $dir/kunder/$server/*
}

show_req() {
	server=$1
	echo "trykk enter for å vise signing request. Denne kopieres inn i control panelet til startssl.com eller andre ssl tilbydere."
	read enter
	cat $dir/kunder/$server/$server.csr
}

store_crt() {
	server=$1
	echo "Trykk enter for å åpne editoren vim, lim deretter inn certifikatet du har generert på startssl"
	echo "avslutt vim ved å taste: <escape> ZZ"
	read enter
	vim $dir/kunder/$server/$server.crt
}

while getopts "h:s:" arg; do
  case $arg in
    h)
      echo "usage" 
      ;;
    s)
      server=$OPTARG
      lag_req $server
      show_req $server
      store_crt $server
      ;;
  esac
done
