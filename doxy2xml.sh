#!/bin/bash

for FI in *.{cpp,h}; do 
	mv ${FI} tmp; 
	gawk -f /bin/doxy2xml.awk tmp | unix2dos >  ${FI}; 
done
