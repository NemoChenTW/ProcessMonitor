#!/bin/bash

##====== Color Setting ======
lightRed="\033[31;1m"
lightGreen="\033[32;1m"
lightYellow="\033[33;1m"
lightBlue="\033[34;1m"
lightPurple="\033[35;1m"
lightCyan="\033[36;1m"

red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
purple="\033[35m"
cyan="\033[36m"

lightReverseRed="\033[31;1;7m"
lightReverseGreen="\033[32;1;7m"
lightReverseYellow="\033[33;1;7m"
lightReverseBlue="\033[34;1;7m"
lightReversePurple="\033[35;1;7m"
lightReverseCyan="\033[36;1;7m"

reverseRed="\033[31;7m"
reverseGreen="\033[32;7m"
reverseYellow="\033[33;7m"
reverseBlue="\033[34;7m"
reversePurple="\033[35;7m"
reverseCyan="\033[36;7m"

colorWhite="\033[37;1m"
colorEnd="\033[0m"
##====== Color Setting ======


if [[ -z "$1" ]]; then
	echo -e "$lightRed There is no arguments. $colorEnd"
elif [[ -n "$2" ]]; then
	echo -e "$lightRed There are too many arguments. $colorEnd"
else
	# Set the process name by input argument
	processName=$1

	oldPid=""

	currentColor=$colorWhite
	averageColor=$colorWhite
	maxColor=$colorWhite

	declare -i memOld=0
	declare -i memCurrent=0

	declare -i memMax=0
	declare -i memAverage=0
	declare -i memAverageOld=0

	declare -i memDiff=0

	#Initial status flag
	declare -i initialCount=0

	declare -a memUsage
	declare -i memUsageMAX=10


	declare -i lowPowerControl=0
	declare -i lowPowerInterval=5

	declare -i outputWaitingTime=1
	declare -i outputShift=1
	declare -i outputCounter=0

	for (( i = 0; i < memUsageMAX; i++ )); do
		sleep 1
		pid_Current=`pidof $processName`
		if [ "$pid_Current" != "$oldPid" ] && [ -n "$pid_Current" ]; then
			oldPid=$pid_Current
			echo -e "$lightReverseYellow ======================== New Program Start. ======================== $colorEnd"

			#============== Initial ==============
			let i=0
			currentColor=$colorWhite
			averageColor=$colorWhite
			maxColor=$colorWhite

			memOld=0
			memCurrent=0
			memMax=0
			memAverage=0
			memAverageOld=0
			memDiff=0
			initialCount=0
			lowPowerControl=0
			lowPowerInterval=5
			outputWaitingTime=1
			outputShift=1
			outputCounter=0
			for (( j = 0; j < memUsageMAX; j++ )); do
				let memUsage[j]=0
			done
			#============== Initial ==============
		fi

		if [ -n "$pid_Current" ]; then
			let memCurrent=`pmap -d $pid_Current | grep mapped | awk '{print $4}' | sed 's/K//g'`
			let memUsage[i]=memCurrent

			let memDiff=memCurrent-memOld
			let memOld=memCurrent
			if [[ "$memDiff" -gt 0 ]]; then
				currentColor=$lightRed
				if [[ "$memCurrent" -gt "$memMax" ]]; then
					let memMax=memCurrent
					maxColor=$lightReverseRed
				else
					maxColor=$colorWhite
				fi
				let lowPowerControl=0
			elif [[ "$memDiff" -lt 0 ]]; then
				currentColor=$lightGreen
				maxColor=$colorWhite
				let lowPowerControl=0
			else
				currentColor=$colorWhite
				maxColor=$colorWhite
				let lowPowerControl=lowPowerControl+1
			fi

			if [[ "$initialCount" -ne 0 ]]; then
				let memAverage=0
				for (( j = 0; j < memUsageMAX; j++ )); do
					let memAverage=memAverage+memUsage[j]
				done
				let memAverage=memAverage/memUsageMAX

				if [[ "$memAverage" -gt "$memAverageOld" ]]; then
					averageColor=$lightRed
				elif [[ "$memAverage" -lt "$memAverageOld" ]]; then
					averageColor=$lightGreen
				else
					averageColor=$colorWhite
				fi
				let memAverageOld=memAverage
			fi


			#Something changed.
			if [[ "$lowPowerControl" -eq 0 ]]; then
				echo -e " $currentColor Current: $memCurrent K ($memDiff) 	$averageColor Average: $memAverage K	$maxColor Max: $memMax K$colorEnd"
				let outputCounter=0
				if [[ "$outputWaitingTime" -ne 1 ]]; then
					let outputWaitingTime=outputWaitingTime/2
				fi

				if [[ "$outputShift" -ne 1 ]]; then
					let outputShift=outputShift/2
				fi
			#Nothing changed.
			else	
				let outputCounter=outputCounter+1
				if [[ "$outputCounter" -ge "$outputWaitingTime" ]]; then
					echo -e " $currentColor Current: $memCurrent K ($memDiff) 	$averageColor Average: $memAverage K	$maxColor Max: $memMax K$colorEnd"
					let outputCounter=0

					if [[ "$lowPowerControl" -ge "$lowPowerInterval" ]]; then
						let outputWaitingTime=outputWaitingTime+outputShift
						let outputShift=outputShift+1
						let lowPowerControl=0
					fi
				fi
			fi

			# echo "outputCounter: $outputCounter.		outputWaitingTime: $outputWaitingTime"

		else
			if [[ "$i" -eq  memUsageMAX/2 ]]; then
				echo -e "$lightRed $processName is not running.$colorEnd"
			fi
		fi

		if [ "$i" -eq 9 ]; then
			let i=0
			let initialCount=1
		fi
	done
fi