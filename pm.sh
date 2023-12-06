packagesNeeded='curl jq'
if [ -x "$(command -v apk)" ];       then sudo apk add --no-cache $packagesNeeded
elif [ -x "$(command -v apt-get)" ]; then sudo apt-get install $packagesNeeded
elif [ -x "$(command -v dnf)" ];     then sudo dnf install $packagesNeeded
elif [ -x "$(command -v pacman)" ];  then sudo pacman -S $packagesNeeded
elif [ -x "$(command -v emerge)" ];  then emerge -avjp $packagesNeeded
elif [ -x "$(command -v yum)" ];     then sudo yum install $packagesNeeded
elif [ -x "$(command -v zypper)" ];  then sudo zypper install $packagesNeeded
elif [ -x "$(command -v apt)" ]; then sudo apt-get install $packagesNeeded
else echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $packagesNeeded">&2; fi