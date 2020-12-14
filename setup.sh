#!/bin/sh

input() {
	if [ $3 ]; then stty -echo; fi
	echo -n $2;
	read res;
	if [ $3 ]; then stty echo; echo ""; fi
	eval $1="$res";
}

input confirm "Would you like to create an auto-source file? (y/n) [y]:"
if [ "$confirm" != "n" ]; then 
	echo "#!/bin/bash\nopwd=\"\$PWD\"\ncd \"\$(dirname \"\$BASH_SOURCE\")\"\n\n" > "./source.sh"
	for file in $(find "./sources" -name "*.sh")
	do
		input confirm "Would you like to source \"$file\"? (y/n) [y]:"
		cmd="source $file";
		if [ "$confirm" = "n" ]; then
			cmd="# $cmd";
		fi
		echo "$cmd" >> "./source.sh";
	done
	echo -e "\ncd \"\$opwd\"" >> "./source.sh";
	chmod u+x "./source.sh";
	if [ -f "$HOME/.bashrc" ]; then
		echo "BashRC detected";
		input confirm "Would you like to add sources to your bashrc? (y/n) [y]:";
		if [ "$confirm" != "n" ]; then
			cmd="source $PWD/source.sh";
			if grep -q "$cmd" "$HOME/.bashrc"; then
				echo "Already in bashrc"
			else
				echo "Not in bashrc, adding..."
				echo "source $PWD/source.sh" >> "$HOME/.bashrc";
			fi
		fi
	fi
fi
