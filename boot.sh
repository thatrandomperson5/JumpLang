# Reserved stuff
curl https://nim-lang.org/choosenim/init.sh -o init.sh -sSf
sh ./init.sh -y
rm init.sh

echo "$(cat ./nimv.txt)" | while read line 
do
   choosenim "$line"
done

nimble refresh