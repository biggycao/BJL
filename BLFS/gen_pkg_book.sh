#!/bin/bash
#
#  Read and parse the configuration parameters..
#
set -e

TRACKFILE=$1
if test -z "$TRACKFILE"; then
  TRACKFILE=tracking-dir/instpkg.xml
fi
TOPDIR=$2
if test -z "$TOPDIR"; then
  TOPDIR=$(pwd)
fi
BLFS_FULL=$3
if test -z "$BLFS_FULL"; then
  BLFS_FULL=${TOPDIR}/blfs-xml/tmp/blfs-full.xml
fi
LFS_FULL=$4
if test -z "$LFS_FULL"; then
  LFS_FULL=${TOPDIR}/lfs-xml/tmp/lfs-full.xml
fi
declare -r ConfigFile="${TOPDIR}/configuration"
declare DepDir="${TOPDIR}/dependencies"
declare LibDir="${TOPDIR}/libs"
declare PackFile="${TOPDIR}/packages.xml"
declare BookXml="${TOPDIR}/book.xml"
declare MakeBook="${TOPDIR}/xsl/make_book.xsl"
declare GetVersion="${TOPDIR}/xsl/get_version.xsl"
declare MakeScripts="${TOPDIR}/xsl/scripts.xsl"
declare ListLFS="${TOPDIR}/xsl/list_lfs.xsl"
declare BookHtml="${TOPDIR}/book-html"
declare BLFS_XML="${TOPDIR}/blfs-xml"
declare -a TARGET
declare DEP_LEVEL
declare SUDO
declare LANGUAGE
declare WRAP_INSTALL
declare PACK_INSTALL
declare DEL_LA_FILES
declare STATS
declare DEP_CHECK
declare SRC_ARCHIVE
declare SRC_SUBDIRS
declare BUILD_ROOT
declare BUILD_SUBDIRS
declare KEEP_FILES
declare -i JOBS
declare CFG_CFLAGS
declare CFG_CXXFLAGS
declare CFG_LDFLAGS

#--------------------------#
parse_configuration() {    #
#--------------------------#
  local	-i cntr=0
  local	-a optTARGET

  while read; do

    # Garbage collection
    case ${REPLY} in
      \#* | '') continue ;;
    esac

    case "${REPLY}" in
      # Create global variables for these parameters.
      optDependency=* | \
      MAIL_SERVER=*   | \
      WRAP_INSTALL=*  | \
      PACK_INSTALL=*  | \
      DEL_LA_FILES=*  | \
      STATS=*         | \
      DEP_CHECK=*     | \
      LANGUAGE=*      | \
      SUDO=*          | \
      SRC_ARCHIVE=*   | \
      SRC_SUBDIRS=*   | \
      BUILD_ROOT=*    | \
      BUILD_SUBDIRS=* | \
      KEEP_FILES=*    | \
      JOBS=*          | \
      CFG_CFLAGS=*    | \
      CFG_CXXFLAGS=*  | \
      CFG_LDFLAGS=*   )  eval ${REPLY} # Define/set a global variable..
                      continue ;;
    esac

    if [[ "${REPLY}" =~ ^CONFIG_ ]]; then
      echo "$REPLY"
      optTARGET[$((cntr++))]=$( echo $REPLY | sed -e 's@CONFIG_@@' -e 's@=y@@' )
    fi
  done < $ConfigFile

  if (( $cntr == 0 )); then
    echo -e "\n>>> NO TARGET SELECTED.. application terminated"
    echo -e "    Run <make> again and select (a) package(s) to build\n"
    exit 0
  fi
  TARGET=(${optTARGET[*]})
  DEP_LEVEL=$optDependency
  SUDO=${SUDO:-n}
  WRAP_INSTALL=${WRAP_INSTALL:-n}
  DEL_LA_FILES=${DEL_LA_FILES:-n}
  STATS=${STATS:-n}
# Other boolean variables are supposed to be either set or unset. Their values
# are not relevant
}

#--------------------------#
validate_configuration() { #
#--------------------------#
  local -r dotSTR=".................."
  local -r PARAM_LIST="DEP_LEVEL SUDO LANGUAGE MAIL_SERVER WRAP_INSTALL PACK_INSTALL DEL_LA_FILES STATS DEP_CHECK SRC_ARCHIVE SRC_SUBDIRS BUILD_ROOT BUILD_SUBDIRS KEEP_FILES JOBS CFG_CFLAGS CFG_CXXFLAGS CFG_LDFLAGS"
  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'
  local config_param
  local -i index

  for config_param in ${PARAM_LIST}; do
    echo -e "`eval echo $PARAM_VALS`"
  done
  for (( index=0 ; index < ${#TARGET[*]} ; index ++ )); do
    echo -e "TARGET${index}${dotSTR:6} ${L_arrow}${BOLD}${TARGET[${index}]}${OFF}${R_arrow}"
  done
}

#
# Generates the root of the dependency tree
#
#--------------------------#
generate_deps() {          #
#--------------------------#

  local -i index
  local DepDir=$1
  rm -f $DepDir/*.{tree,dep}
  for (( index=0 ; index < ${#TARGET[*]} ; index ++ )); do
    echo 1 b ${TARGET[${index}]} >> $DepDir/root.dep
  done
}

#
# Clean configuration file keeping only global default settings.
# That prevent "trying to assign nonexistent symbol" messages
# and assures that there is no TARGET selected from a previous run
#
#--------------------------#
clean_configuration() {    #
#--------------------------#

tail -n 15 ${ConfigFile} > ${ConfigFile}.tmp
mv ${ConfigFile}.tmp ${ConfigFile}

}

#---------------------
# Constants
source ${LibDir}/constants.inc
[[ $? > 0 ]] && echo -e "\n\tERROR: constants.inc did not load..\n" && exit

#---------------------
# Dependencies module
source ${LibDir}/func_dependencies
[[ $? > 0 ]] && echo -e "\n\tERROR: func_dependencies did not load..\n" && exit

#------- MAIN --------
if [[ ! -f ${PackFile} ]] ; then
  echo -e "\tNo packages file has been found.\n"
  echo -e "\tExecution aborted.\n"
  exit 1
fi


parse_configuration
validate_configuration
echo "${SD_BORDER}${nl_}"
echo -n "Are you happy with these settings? yes/no (no): "
read ANSWER
if [ x$ANSWER != "xyes" ] ; then
  echo "${nl_}Rerun make and fix your settings.${nl_}"
  exit 1
fi
echo "${nl_}${SD_BORDER}${nl_}"

rm -rf $DepDir
mkdir $DepDir
generate_deps $DepDir
pushd $DepDir > /dev/null
set +e
generate_subgraph root.dep 1 1 b
echo -e "\n${SD_BORDER}"
echo Graph contains $(ls |wc -l) nodes
echo -e "${SD_BORDER}"
echo Cleaning subgraph...
clean_subgraph
echo done
echo Generating the tree
echo 1 >  root.tree
echo 1 >> root.tree
cat root.dep >> root.tree
generate_dependency_tree root.tree 1
echo -e "\n${SD_BORDER}"
echo Generating the ordered full dependency list
FULL_LIST="$(tree_browse root.tree)"
set -e
popd > /dev/null
#echo "$FULL_LIST"
#echo -e \\n provisional end...
#exit
echo Generating the ordered package list
LIST=
while read p; do
    if [ "$p" != "${p%-pass1}" ]; then
# If the pass2 is installed, no need for pass1. We get its
# installed version from TRACKFILE; We could use PackFile, but
# the test would be slightly more complicated.
echo Treating $p
        pass2_v=$(xsltproc --stringparam package "${p%-pass1}" \
                  $GetVersion $TRACKFILE | head -n1)
echo Found pass2_v=$pass2_v
        if [ -n "$pass2_v" ]; then continue; fi
# We need to get the installed version from TRACKFILE
        inst_v=$(xsltproc --stringparam package "$p" $GetVersion $TRACKFILE | \
                 head -n1)
        if [ -z "$inst_v" ]; then inst_v=0; fi
echo Found inst_v=$inst_v
# The available version is taken from PackFile
        avail_v=$(xsltproc --stringparam package "${p%-pass1}" \
		  $GetVersion $PackFile | head -n1)
echo Found avail_v=$avail_v
        versions="$avail_v
$inst_v"
	echo which gives versions=$versions
    else
        versions=$(xsltproc --stringparam package "$p" $GetVersion $PackFile)
    fi
    if [ "$versions" != "$(sort -V <<<$versions)" ]; then
        LIST="$LIST $p"
    fi
done <<<$FULL_LIST
#echo \""$LIST"\"
#echo -e \\n provisional end...
#exit
rm -f ${BookXml}
echo Making XML book
xsltproc --stringparam list    "$LIST"        \
         --stringparam MTA     "$MAIL_SERVER" \
         --stringparam lfsbook "$LFS_FULL"    \
         -o ${BookXml} \
         ${MakeBook} \
         $BLFS_FULL
echo "making HTML book (may take some time...)"
xsltproc -o ${BookHtml}/ \
         -stringparam chunk.quietly 1 \
         ${BLFS_XML}/stylesheets/blfs-chunked.xsl \
         ${BookXml}
if [ ! -d ${BookHtml}/stylesheets ]
  then mkdir -p ${BookHtml}/stylesheets
  cp ${BLFS_XML}/stylesheets/lfs-xsl/*.css ${BookHtml}/stylesheets
fi
if [ ! -d ${BookHtml}/images ]
  then mkdir -p ${BookHtml}/images
  cp ${BLFS_XML}/images/*.png ${BookHtml}/images
fi
for ht in ${BookHtml}/*.html
  do sed -i 's@\.\./stylesheets@stylesheets@' $ht
  sed -i 's@\.\./images@images@' $ht
done
echo -en "\n\tGenerating the build scripts ...\n"
rm -rf scripts
if test $STATS = y; then
  LIST_STAT="${TARGET[*]}"
else
  LIST_STAT=""
fi
xsltproc --xinclude --nonet                           \
         --stringparam language      "$LANGUAGE"      \
         --stringparam sudo          "$SUDO"          \
         --stringparam wrap-install  "$WRAP_INSTALL"  \
         --stringparam pack-install  "$PACK_INSTALL"  \
         --stringparam del-la-files  "$DEL_LA_FILES"  \
         --stringparam list-stat     "$LIST_STAT"     \
         --stringparam src-archive   "$SRC_ARCHIVE"   \
         --stringparam src-subdirs   "$SRC_SUBDIRS"   \
         --stringparam build-root    "$BUILD_ROOT"    \
         --stringparam build-subdirs "$BUILD_SUBDIRS" \
         --stringparam keep-files    "$KEEP_FILES"    \
         --param       jobs          "$JOBS"          \
         --stringparam cfg-cflags    "$CFG_CFLAGS"    \
         --stringparam cfg-cxxflags  "$CFG_CXXFLAGS"  \
         --stringparam cfg-ldflags   "$CFG_LDFLAGS"   \
	 --stringparam fqdn          "$(hostname -f)" \
         --output      ./scripts/                     \
         ${MakeScripts}                               \
         ${BookXml}
# Make the scripts executable.
chmod -R +x scripts
echo -e "done\n"

if [ -n "$DEP_CHECK" ]; then
   if (( ${#TARGET[*]} != 1 )); then
      printf "\nWARNING: If dependencies are checked, only one package\n"
      printf "         shoud be selected. Not generating check code.\n"
      exit
   fi

   LIST_LFS="$(xsltproc $ListLFS $LFS_FULL)"
   LIST_NEEDED="$(echo $FULL_LIST)"
   LIST_INSTALLED="$(porg -a | sed 's/-[[:digit:]].*//')"
   LIST_UNNEEDED=
   for p in $LIST_INSTALLED; do
      case " $LIST_LFS " in *" $p "*)  continue ;; esac
      case " $LIST_NEEDED " in *" $p "*)  continue ;; esac
      LIST_UNNEEDED="$LIST_UNNEEDED $p"
   done
   cat >head.tmp <<EOF
#!/bin/bash
set -e

# Remove all unneeded packages
VERSIONED_LIST=
for p in $LIST_UNNEEDED; do
   VERSIONED_LIST="\$VERSIONED_LIST \$(porg \$p)"
   sudo porg -rb \$p
done

# Function to restore packages
restore_pack () {
for p in \$VERSIONED_LIST; do
   sudo porgball -e -l /var/lib/packages/\${p}.porg.tar.gz
done
}

trap restore_pack ERR

EOF
   cat >tail.tmp <<EOF
restore_pack
exit
EOF

   sed -e "1,2d" -e '$d' scripts/*${TARGET} >script.tmp
   cat head.tmp script.tmp tail.tmp >scripts/*${TARGET}
   rm *.tmp
fi
#clean_configuration
