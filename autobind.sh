#!/bin/bash

logicbind="/tmp/"$(head /dev/random | sha512sum | cut -d " " -f 1)
realbind="/tmp/"$(head /dev/random | sha512sum | cut -d " " -f 1)
echo $logicbind
echo $realbind
echo 1 > $realbind

trap "sh -c \"sleep 3
cat $realbind
if [ \\\$(cat $realbind) = 0 ]; then
	echo 'end real bind'
	echo 'i2c-ELAN0001:00' > /sys/bus/i2c/drivers/elants_i2c/bind
fi
rm $logicbind $realbind
echo end\"&" SIGINT

evtest /dev/input/event1 | grep --line-buffered "type 1 (EV_KEY), code 320 (BTN_TOOL_PEN)" | while read line; do
	echo $line | grep -q "value 1"
	if [[ $? == 0 ]]; then
		echo "unbind"
		echo 0 > $logicbind
		if [ $(cat $realbind) = 1 ]; then
			echo 'real unbind'
			echo 'i2c-ELAN0001:00' > /sys/bus/i2c/drivers/elants_i2c/unbind
		fi
		echo 0 > $realbind
	else
		echo "bind"
		echo 1 > $logicbind
		echo "kill $!"
		kill $! 2>/dev/null || true
		sh -c "sleep 3
		cat $logicbind
		if [ \$(cat $logicbind) = 1 ]; then
			echo 'real bind'
			echo 'i2c-ELAN0001:00' > /sys/bus/i2c/drivers/elants_i2c/bind
			echo 1 > $realbind
		else
			echo 'not bind'
		fi
		"&
	fi
done
