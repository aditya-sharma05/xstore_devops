if [ $# -eq 3 ]
then
cat "$1" | grep "$2 $3"
else
cat "$1" | grep "$2"
fi

