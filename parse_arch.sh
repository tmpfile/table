#!/bin/sh

#apk add coreutils (busybox doesn't have paste)
#git clone https://git.alpinelinux.org/cgit/aports/

grep "arch=" ./aports/main/*/APKBUILD -m 1 | \
    sed -e 's/\/APKBUILD//g'                 \
        -e 's/\.\/aports\///g'               \
        -e 's/arch=//g'                      \
        -e 's/"//g'                          \
        -e "s/'//g"                          \
        -e 's/noarch/all/g'                  \
        -e 's/:all/:x86 x86_64 armhf aarch64 ppc64le s390x/g' > tmp

grep -v ! tmp > clean
grep ! tmp > not
rm tmp

ARCH='x86 x86_64 armhf aarch64 ppc64le s390x'

for arch in $ARCH
do
    grep !$arch not | sed 's/'$arch'//g' > not_$arch
    grep -v !$arch not > tmp
    cat not_$arch tmp > not
    rm tmp not_$arch
done

sed -e 's/!//g' \
    -e 's/  / /g' \
    -e 's/ *$//' \
    -e 's/: /:/g' \
    -e 's/_64/x86_64/g' \
    -e 's/x86x86_64/x86_64/g' \
-i not

cat clean not > file
rm clean not

for arch in $ARCH
do
    sed 's/'$arch'/'$arch';/g' -i file
done

sed 's/x86;_64/x86_64;/g' -i file

sed 's/ //g' -i file

sed -e 's/x86;/100000+/g'      \
    -e 's/x86_64;/10000+/g'   \
    -e 's/armhf;/1000+/g'    \
    -e 's/aarch64;/100+/g'  \
    -e 's/ppc64le;/10+/g'  \
    -e 's/s390x;/1+/g'    \
-i file

sed -e 's/+*$//' \
    -e 's/^/printf "/g' \
    -e 's/:/:%06d\\n" $((/g' \
    -e 's/$/))/g' \
-i file

sed '1 i\#!/bin/sh' -i file

# these 2 lines were broken, remove for now
grep -v alpine-keys file > tmp
grep -v argp-standalone tmp > file
rm tmp

sh file > table
rm file

cut -d':' -f1 table > f1
cut -d':' -f2 table > f2

sed 's/\(.\)/\1,/g' -i f2
paste -d, f1 f2 > table
rm f1 f2

sed 's/,*$//' -i table

sort table -o table
sed '1 i\,x86,x86_64,armhf,aarch64,ppc64le,s390x' table > complete_table.csv

grep -v ,1,1,1,1,1,1 table > missing_support_table.csv
sed '1 i\,x86,x86_64,armhf,aarch64,ppc64le,s390x' -i missing_support_table.csv
rm table

# We now have a csv file like this
# ,x86,x86_64,armhf,aarch64,ppc64le,s390x
# package-A,1,0,0,1,0,1
# package-B,1,0,1,1,1,1

