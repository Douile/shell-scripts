#!/bin/sh

input() {
	if [ $3 ]; then stty -echo; fi
	echo -n $2;
	read res;
	if [ $3 ]; then stty echo; echo ""; fi
	eval $1="$res";
}

getdir() {
	dir="$1"
	input confirm "Will install scripts to \"$dir\" would you like to change this? (y/n) [n]:" 
	if [ "$confirm" = "y" ]; then
		input newdir "Enter directory to install to:"
		getdir "$newdir" dir
	fi
	eval $2="$dir"
}


startpwd="$PWD"
getdir "$PWD/tscripts/" installdir
if [ ! -d "$installdir" ]; then
	input confirm "\"$installdir\" doesn't exist would you like to create it? (y/n) [y]:"
	if [ "$confirm" = "n" ]; then
		echo "No install dir exiting...";
		exit 1;
	fi
	mkdir -p "$installdir"
fi
echo "INSTALLDIR: $installdir"
cd $installdir
git clone "https://github.com/Douile/bash-scripts.git" .
