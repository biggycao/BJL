<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"
              encoding='ISO-8859-1'/>

  <xsl:template match="/">
    <xsl:apply-templates select="//list"/>
    <xsl:text>comment ""

menu    "Build settings"

    choice
        prompt  "Mail server for resolving the MTA dependency"
        config  MS_sendmail
                bool    "sendmail"
        config  MS_postfix
                bool    "postfix"
        config  MS_exim
                bool    "exim"
    endchoice
    config  MAIL_SERVER
        string
        default "sendmail"        if MS_sendmail
        default "postfix"         if MS_postfix
        default "exim"            if MS_exim

    choice
        prompt  "Dependency level"
        default DEPLVL_2
        help
            Packages included in the dependency graph. Note that the graph
            itself contains all the dependency information relating those
            packages.

        config  DEPLVL_1
        bool    "Required dependencies only"

        config  DEPLVL_2
        bool    "Required plus recommended dependencies"

        config  DEPLVL_3
        bool    "Req/rec  plus optional dependencies of requested package(s)"

        config  DEPLVL_4
        bool    "All non external dependencies"

    endchoice
    config  optDependency
        int
        default 1       if DEPLVL_1
        default 2       if DEPLVL_2
        default 3       if DEPLVL_3
        default 4       if DEPLVL_4

    config  LANGUAGE
        string "LANG variable in the form ll_CC.charmap[@modifiers]"
        default "en_US.UTF-8"
        help
            Because of the book layout, the 3 fields, ll, CC and charmap are
            mandatory. The @modifier is honoured if present.

    config  SUDO
        bool "Build as User"
        default y
        help
            Select if sudo will be used (you build as a normal user)
                    otherwise sudo is not needed (you build as root)

    config  WRAP_INSTALL
        bool "Use `porg style' package management"
        default n
        help
            Select if you want the installation commands to be wrapped
            between "wrapInstall '" and "' ; packInstall" functions,
            where wrapInstall is used to set up a LD_PRELOAD library (for
            example using porg), and packInstall makes the package tarball

        config  PACK_INSTALL
            string     "Location of the packInstall.sh script"
            default    "/blfs_root/packInstall.sh" if !SUDO
            default    "$HOME/blfs_root/packInstall.sh" if SUDO
            depends on WRAP_INSTALL
            help
                This script is needed for the proper operation of the
                `porg style' package management. Provide an absolute
                path.

    config	DEL_LA_FILES
    bool "Remove libtool .la files after package installation"
    default y
    help
            This option should be active on any system mixing libtool
            and meson build systems. ImageMagick .la files are preserved.

    config	STATS
    bool "Generate statistics for the requested package(s)"
    default n
    help
            If you want timing and memory footprint statistics to be
            generated for the packages you build (not their dependencies),
            set this option to y. Due to the book layout, several scripts
            are not functional in this case. Please review them.

    config	DEP_CHECK
    bool "Check dependencies of the requested package(s)"
    default n
    depends on WRAP_INSTALL
    help
      Setting this option does not work if more than one package
      is selected. It will do the following:
      - Build the dependency tree and generate a build ordered list
        disregarding already installed packages
      - Generate the scripts for the dependencies not already
        installed (as usual)
      - Generate a stript that:
        + removes all unneeded packages using porg
          (at this point the blfs_tools cannot be used anymore,
          and your system may be non functional, so use a console
          for that, not a graphical environment)
        + installs the package
        + restores all the previously removed packages
      Note that this script may not be the last one, if there are runtime
      dependencies

endmenu

menu "Build Layout"
    config  SRC_ARCHIVE
        string  "Directory of sources"
        default "/sources"
    config  SRC_SUBDIRS
        bool    "Downloads sources to subdirectories"
        default n
        help
            If this option is set, the sources will be downloaded and archived
            into a subdirectory of the source directory, one for each page
            of the book. Otherwise they are downloaded and archived directly
            into the source directory
    config  BUILD_ROOT
        string  "Build directory"
        default "/sources"
        help
            Directory where the build occurs. It can be the same as the
            source directory, provided the setting of subdirectories is
            different
    config  BUILD_SUBDIRS
        bool    "Build into subdirectories"
        default y
        help
            If this option is set, the sources will be extracted into
            subdirectories of the build directory. Otherwise, they will be
            directly extracted into the build directory
    config  KEEP_FILES
        bool    "Keep source directory"
        default n
        help
            Set this option if you want to keep the build directories
            for further examination after installing the package
endmenu

menu    "Optimization"
    config JOBS
        int     "Number of parallel jobs"
        default 0
        help
            This number will get passed to make or ninja, unless set
            to 0, in which case, it is set to the number of processors
            on line. Note that some packages do not respect this setting.
            Also, "-j1" is always passed to make for install (and nothing
            to ninja).
    config CFG_CFLAGS
        string  "Content of variable CFLAGS"
        default "EMPTY"
        help
            If set to the special string "EMPTY", then CFLAGS will be
            unset before starting the script. Otherwise, there is no
            content check for this variable. Double check for typos!
    config CFG_CXXFLAGS
        string  "Content of variable CXXFLAGS"
        default "EMPTY"
        help
            If set to the special string "EMPTY", then CXXFLAGS will be
            unset before starting the script. Otherwise, there is no
            content check for this variable. Double check for typos!
    config CFG_LDFLAGS
        string  "Content of variable LDFLAGS"
        default "EMPTY"
        help
            If set to the special string "EMPTY", then LDFLAGS will be
            unset before starting the script. Otherwise, there is no
            content check for this variable. Double check for typos!
endmenu
</xsl:text>
  </xsl:template>

  <xsl:template match="list">
    <xsl:if
      test=".//*[self::package or self::module]
                    [(version and not(inst-version)) or
                      string(version) != string(inst-version)]">
      <xsl:text>menuconfig&#9;MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>
bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
default&#9;n

if&#9;MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>

</xsl:text>
      <xsl:apply-templates select="sublist"/>
      <xsl:text>endif

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="sublist">
    <xsl:if
      test=".//*[self::package or self::module]
                    [(version and not(inst-version)) or
                      string(version) != string(inst-version)]">
      <xsl:text>&#9;menuconfig&#9;MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>
&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;default&#9;n

&#9;if&#9;MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>

</xsl:text>
      <xsl:apply-templates select="package"/>
      <xsl:text>&#9;endif

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="package">
    <xsl:if
      test="(version and not(inst-version)) or
                      string(version) != string(inst-version)">
      <xsl:text>&#9;&#9;config&#9;CONFIG_</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>
&#9;&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="version"/>
      <xsl:if test="inst-version">
        <xsl:text> [Installed </xsl:text>
        <xsl:value-of select="inst-version"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
      <xsl:text>"
&#9;&#9;default&#9;n

</xsl:text>
    </xsl:if>
    <xsl:if
      test="not(version) and ./module[not(inst-version) or
                      string(version) != string(inst-version)]">
      <xsl:text>&#9;&#9;menuconfig&#9;MENU_</xsl:text>
      <xsl:value-of select="translate(name,' ()','___')"/>
      <xsl:text>
&#9;&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;&#9;default&#9;n

&#9;&#9;if&#9;MENU_</xsl:text>
      <xsl:value-of select="translate(name,' ()','___')"/>
      <xsl:text>

</xsl:text>
      <xsl:apply-templates select="module"/>
      <xsl:text>&#9;&#9;endif

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="module">
    <xsl:if
      test="not(inst-version) or
            string(version) != string(inst-version)">
      <xsl:text>&#9;&#9;&#9;config&#9;CONFIG_</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>
&#9;&#9;&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="version"/>
      <xsl:if test="inst-version">
        <xsl:text> [Installed </xsl:text>
        <xsl:value-of select="inst-version"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
      <xsl:text>"
&#9;&#9;&#9;default&#9;</xsl:text>
      <xsl:choose>
        <xsl:when test="contains(../name,'xorg')">
          <xsl:text>y

</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>n

</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
