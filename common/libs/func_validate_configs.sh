declare -r dotSTR=".................."


#----------------------------#
validate_config() {          # Are the config values sane (within reason)
#----------------------------#
: <<inline_doc
      Validates the configuration parameters.

    input vars: none
    externals:  color constants
    modifies:   none
    returns:    nothing
    on error:   write text to console and dies
    on success: write text to console and returns
inline_doc

  # Common settings by Config.in sections and books family
  local -r     BOOK_common="COMMIT BOOK CUSTOM_TOOLS"
  local -r  GENERAL_common="LUSER LGROUP LHOME BUILDDIR CLEAN GETPKG SRC_ARCHIVE \
                            RETRYSRCDOWNLOAD RETRYDOWNLOADCNT DOWNLOADTIMEOUT \
                            RUNMAKE"
  local -r    BUILD_chroot="TEST STRIP"
  local -r    BUILD_common="FSTAB CONFIG TIMEZONE PAGE LANG INSTALL_LOG"
  local -r ADVANCED_chroot="COMPARE RUN_ICA ITERATIONS OPTIMIZE"
  local -r ADVANCED_common="REPORT REBUILD_MAKEFILE"

  # BOOK Settings by book
  local -r   LFS_book="$BOOK_common INITSYS BLFS_TOOL"

  # Build Settings by book
  local -r   LFS_build="$BUILD_chroot NCURSES5 $BUILD_common PKGMNGT FULL_LOCALE WRAP_INSTALL"

  # System Settings by book
  local -r LFS_system="HOSTNAME INTERFACE IP_ADDR GATEWAY PREFIX BROADCAST DOMAIN DNS1 DNS2 FONT KEYMAP LOCAL LOG_LEVEL"

  # Full list of books settings
  local -r   lfs_PARAM_LIST="$LFS_book   $GENERAL_common $LFS_build $LFS_system  $ADVANCED_chroot ALL_CORES CPUSET N_PARALLEL REALSBU SAVE_CH5 $ADVANCED_common"
#  local -r  blfs_PARAM_LIST="BRANCH_ID BLFS_ROOT BLFS_XML TRACKING_DIR"

  # Additional variables
  local -r blfs_tool_PARAM_LIST="\
     BLFS_COMMIT BLFS_ROOT BLFS_XML TRACKING_DIR \
     DEP_LIBXML DEP_LIBXSLT DEP_DBXML DEP_LYNX DEP_SUDO DEP_WGET \
     DEP_GIT DEP_GPM"
  local -r custom_tool_PARAM_LIST="TRACKING_DIR"

  # Internal variables
  local -r ERROR_MSG_pt1='The variable \"${L_arrow}${config_param}${R_arrow}\" value ${L_arrow}${BOLD}${!config_param}${R_arrow} is invalid,'
  local -r ERROR_MSG_pt2='rerun make and fix your configuration settings${OFF}'
  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

  local PARAM_LIST=
  local config_param
  local validation_str
  local save_param

  write_error_and_die() {
    echo -e "\n${DD_BORDER}"
    echo -e "`eval echo ${ERROR_MSG_pt1}`" >&2
    echo -e "`eval echo ${ERROR_MSG_pt2}`" >&2
    echo -e "${DD_BORDER}\n"
    exit 1
  }

# This function is only used when testing package management files.
  write_pkg_and_die() {
    echo -e "\n${DD_BORDER}"
    echo    "Package management is requested but" >&2
    echo -e $* >&2
    echo -e "${DD_BORDER}\n"
    exit 1
  }

  validate_file() {
     # For parameters ending with a '+' failure causes a warning message only
     echo -n "`eval echo $PARAM_VALS`"
     while test $# -gt 0 ; do
       case $1 in
        # Failures caused program exit
        "-z")  [[   -z "${!config_param}" ]] && echo "${tab_}<-- NO file name given"  && write_error_and_die ;;
        "-e")  [[ ! -e "${!config_param}" ]] && echo "${tab_}<-- file does not exist" && write_error_and_die ;;
        "-s")  [[ ! -s "${!config_param}" ]] && echo "${tab_}<-- file has zero bytes" && write_error_and_die ;;
        "-r")  [[ ! -r "${!config_param}" ]] && echo "${tab_}<-- no read permission " && write_error_and_die ;;
        "-w")  [[ ! -w "${!config_param}" ]] && echo "${tab_}<-- no write permission" && write_error_and_die ;;
        "-x")  [[ ! -x "${!config_param}" ]] && echo "${tab_}<-- file cannot be executed" && write_error_and_die ;;
        # Warning messages only
        "-z+") [[   -z "${!config_param}" ]] && echo && return ;;
       esac
       shift 1
     done
     echo
  }

  validate_dir() {
     # For parameters ending with a '+' failure causes a warning message only
     echo -n "`eval echo $PARAM_VALS`"
     while test $# -gt 0 ; do
       case $1 in
        "-z") [[   -z "${!config_param}" ]] && echo "${tab_}NO directory name given" && write_error_and_die ;;
        "-d") [[ ! -d "${!config_param}" ]] && echo "${tab_}This is NOT a directory" && write_error_and_die ;;
        "-w") if [[ ! -w "${!config_param}" ]]; then
                echo "${nl_}${DD_BORDER}"
                echo "${tab_}${RED}You do not have ${L_arrow}write${R_arrow}${RED} access to the directory${OFF}"
                echo "${tab_}${BOLD}${!config_param}${OFF}"
                echo "${DD_BORDER}${nl_}"
                exit 1
              fi  ;;
        # Warnings only
        "-w+") if [[ ! -w "${!config_param}" ]]; then
                 echo "${nl_}${DD_BORDER}"
                 echo "${tab_}WARNING-- You do not have ${L_arrow}write${R_arrow} access to the directory${OFF}"
                 echo "${tab_}       -- ${BOLD}${!config_param}${OFF}"
                 echo "${DD_BORDER}"
               fi  ;;
        "-z+") [[ -z "${!config_param}" ]] && echo "${tab_}<-- NO directory name given" && return
       esac
       shift 1
     done
     echo
  }

  set +e
  for config_param in $lfs_PARAM_LIST; do
    case $config_param in
      # Envvars that depend on other settings to be displayed
      COMPARE)          [[ ! "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RUN_ICA)          [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      ITERATIONS)       [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      TARGET32)         [[ -n "${TARGET32}" ]] &&  echo -e "`eval echo $PARAM_VALS`" ;;
      MIPS_LEVEL)       [[ "${ARCH}" = "mips" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RETRYSRCDOWNLOAD) [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RETRYDOWNLOADCNT) [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      DOWNLOADTIMEOUT)  [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      CPUSET)           [[ "$HAVE_CGROUP" = "y" ]] && [[ "$ALL_CORES" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      N_PARALLEL)       [[ "$ALL_CORES" = "n" ]] && echo -e "`eval echo $PARAM_VALS`" ;;

      # Envars that requires some validation
      LUSER)      echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                  ;;
      LGROUP)     echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                  ;;
        # BOOK validation. Very ugly, need be fixed
      BOOK)        if [[ "${WORKING_COPY}" = "y" ]] ; then
                     validate_dir -z -d
                   else
                     echo -e "`eval echo $PARAM_VALS`"
                   fi
                  ;;
        # Validate directories, testable states:
        #  fatal   -z -d -w,
        #  warning -z+   -w+
      SRC_ARCHIVE) [[ "$GETPKG" = "y" ]] && validate_dir -z+ -d -w+ ;;
        # The build directory/partition MUST exist and be writable by the user
      BUILDDIR)   validate_dir -z -d
                  [[ "xx x/x" =~ x${!config_param}x ]] && write_error_and_die ;;
      LHOME)      validate_dir -z -d ;;

        # Validate files, testable states:
        #  fatal   -z -e -s -w -x -r,
        #  warning -z+
      FSTAB)       validate_file -z+ -e -s ;;
      CONFIG)      validate_file -z+ -e -s ;;
      BOOT_CONFIG) [[ "${METHOD}" = "boot" ]] && validate_file -z -e -s ;;

        # Treatment of LANG parameter
      LANG )  # See if the locale value has been set
               echo -n "`eval echo $PARAM_VALS`"
               [[ -z "${!config_param}" ]] &&
                 echo " -- Variable $config_param cannot be empty!" &&
                 write_error_and_die
               echo
               ;;

        # Treatment of HOSTNAME
      HOSTNAME)  echo -e "`eval echo $PARAM_VALS`"
                 [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                 ;;

        # Case of PKGMNGT: two files, packageManager.xml and packInstall.sh
        # must exist in $PKGMNGTDIR if PKGMNGT='y':
      PKGMNGT) echo -e "`eval echo $PARAM_VALS`"
               if [ "$PKGMNGT" = y ]; then
                 if [ ! -e "$PKGMNGTDIR/packageManager.xml" ]; then
                   write_pkg_and_die $PKGMNGTDIR/packageManager.xml does not exist
                 fi
                 if [ ! -e "$PKGMNGTDIR/packInstall.sh" ]; then
                   write_pkg_and_die $PKGMNGTDIR/packInstall.sh does not exist
                 fi
                 if [ ! -s "$PKGMNGTDIR/packageManager.xml" ]; then
                   write_pkg_and_die $PKGMNGTDIR/packageManager.xml has zero size
                 fi
                 if [ ! -s "$PKGMNGTDIR/packInstall.sh" ]; then
                   write_pkg_and_die $PKGMNGTDIR/packInstall.sh has zero size
                 fi
                 if [ ! -r "$PKGMNGTDIR/packageManager.xml" ]; then
                   write_pkg_and_die $PKGMNGTDIR/packageManager.xml is not readable
                 fi
                 if [ ! -r "$PKGMNGTDIR/packInstall.sh" ]; then
                   write_pkg_and_die $PKGMNGTDIR/packInstall.sh is not readable
                 fi
               fi
               ;;
      # Display non-validated envars found in lfs_PARAM_LIST
      * ) echo -e "`eval echo $PARAM_VALS`" ;;

    esac
  done

  if [[ "${BLFS_TOOL}" = "y" ]] ; then
    echo "${nl_}    ${BLUE}blfs-tool settings${OFF}"
    for config_param in ${blfs_tool_PARAM_LIST}; do
      echo -e "`eval echo $PARAM_VALS`"
    done
  fi

  if [[ "${CUSTOM_TOOLS}" = "y" ]] && [[ "${BLFS_TOOL}" = "n" ]]  ; then
    for config_param in ${custom_tool_PARAM_LIST}; do
      echo -e "`eval echo $PARAM_VALS`"
    done
  fi

  set -e
  echo "${nl_}***${BOLD}${GREEN} ${PARAM_GROUP%%_*T} config parameters look good${OFF} ***${nl_}"
}
