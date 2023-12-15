bail() { echo "FATAL: $1"; exit 1; }
if [ -x "$(command -v apt-get)" ]; then sudo apt-get install $(check.sh)  || bail "packages cannot be installed."
elif [ -x "$(command -v dnf)" ];     then sudo dnf install $(check.sh)    || bail "packages cannot be installed."
elif [ -x "$(command -v pacman)" ];  then sudo pacman -S $(check.sh)      || bail "packages cannot be installed."
elif [ -x "$(command -v emerge)" ];  then emerge -avjp $(check.sh)        || bail "packages cannot be installed."
elif [ -x "$(command -v yum)" ];     then sudo yum install $(check.sh)    || bail "packages cannot be installed."
elif [ -x "$(command -v zypper)" ];  then sudo zypper install $(check.sh) || bail "packages cannot be installed."
elif [ -x "$(command -v apt)" ]; then sudo apt-get install $(check.sh)    || bail "packages cannot be installed."
else echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $(check.sh)">&2; exit 1
bash addcheck.sh