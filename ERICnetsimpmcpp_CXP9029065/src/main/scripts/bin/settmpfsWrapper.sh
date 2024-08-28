#!/bin/sh


if [ "$NETSIMDIR" = "" ] ; then
NETSIMDIR=$HOME/netsimdir
fi

rm -rf /netsim_users/pms/etc/Simulations.txt

ls -1 /netsim/netsimdir/*/simulation.netsimdb | sed -e "s/.simulation.netsimdb//g" -e "s/^[^*]*[*\/]//g" | grep -v "default" > /netsim_users/pms/etc/Simulations.txt

if [ -s /netsim_users/pms/etc/Simulations.txt ]
then
while read sim
do
/netsim_users/pms/bin/set_tmpfs.sh $sim
done < /netsim_users/pms/etc/Simulations.txt
fi
