echo "3.1 INTRO"
mkdir -v /mnt/lfs/sources
chmod -v a+wt /mnt/lfs/sources
cd /mnt/lfs/sources
wget https://mirrors.ustc.edu.cn/lfs/lfs-packages/lfs-packages-12.0.tar
tar -xf lfs-packages-12.0.tar
cp 12.0/* .
chown root:root /mnt/lfs/sources/*
echo "CHAPTER 3 DONE"
echo "4.2. Creating a Limited Directory Layout in the LFS Filesystem"
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
mkdir -pv $LFS/tools

echo "4.3. Adding the LFS User"
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo ENTER YOUR LFS USER PASSWORD
passwd lfs
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
cat << EOF | su - lfs
ls /
EOF
