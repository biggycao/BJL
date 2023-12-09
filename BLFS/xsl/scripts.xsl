﻿<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from "linear build" BLFS books. -->

<!-- parameters and global variables -->
  <!-- Check whether the book is sysv or systemd -->
  <xsl:variable name="rev">
    <xsl:choose>
      <xsl:when test="//bookinfo/title/phrase[@revision='systemd']">
        systemd
      </xsl:when>
      <xsl:otherwise>
        sysv
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Wrap "root" commands inside a wrapper function, allowing
       "porg style" package management -->
  <xsl:param name="wrap-install" select="'n'"/>
  <xsl:param name="pack-install" select="'$HOME/blfs_root/packInstall.sh'"/>

  <!-- list of packages needing stats -->
  <xsl:param name="list-stat" select="''"/>

  <!-- Remove libtool .la files -->
  <xsl:param name="del-la-files" select="'y'"/>

  <!-- Build as user (y) or as root (n)? -->
  <xsl:param name="sudo" select="'y'"/>

  <!-- Root of sources directory -->
  <xsl:param name="src-archive" select="'/sources'"/>

  <!-- Download and archive tarballs to subdirs. Can be 'y' or '',
       not 'n' -->
  <xsl:param name="src-subdirs" select="''"/>

  <!-- Root of build directory -->
  <xsl:param name="build-root" select="'/sources'"/>

  <!-- extract sources and build into subdirs. Can be 'y' or '',
       not 'n' -->
  <xsl:param name="build-subdirs" select="''"/>

  <!-- Keep files in the build directory after building. Can be 'y' or '',
       not 'n' -->
  <xsl:param name="keep-files" select="''"/>

  <!-- Number of parallel jobs; type integer, not string -->
  <xsl:param name="jobs" select="0"/>
<!-- simple instructions for removing .la files. -->
<!-- We'll use the rule that any text output begins with a linefeed if needed
     so that we do not need to output one at the end-->
  <xsl:variable name="la-files-instr">

for libdir in /lib /usr/lib $(find /opt -name lib); do
  find $libdir -name \*.la           \
             ! -path \*ImageMagick\* \
               -delete
done</xsl:variable>

  <xsl:variable name="list-stat-norm"
                select="concat(' ', normalize-space($list-stat),' ')"/>

<!-- To be able to use the single quote in tests -->
  <xsl:variable name="APOS">'</xsl:variable>

<!-- end parameters and global variables -->

<!-- include the template for processing screen children of
     role="install" sect2 -->
  <xsl:include href="process-install.xsl"/>

<!-- include the template for replaceable tags -->
  <xsl:include href="process-replaceable.xsl"/>

<!--=================== Begin processing ========================-->

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1[@id != 'bootscripts' and
                                         @id != 'systemd-units']"/>
  </xsl:template>

<!--=================== Master chunks code ======================-->

  <xsl:template match="sect1">

    <!-- Are stat requested for this page? -->
    <xsl:variable name="want-stats"
                  select="contains($list-stat-norm,
                                   concat(' ',@id,' '))"/>

      <!-- The file names -->
    <xsl:variable name="filename" select="@id"/>

      <!-- The build order -->
    <xsl:variable name="position" select="position()"/>
    <xsl:variable name="order">
      <xsl:choose>
        <xsl:when test="string-length($position) = 1">
          <xsl:text>00</xsl:text>
          <xsl:value-of select="$position"/>
        </xsl:when>
        <xsl:when test="string-length($position) = 2">
          <xsl:text>0</xsl:text>
          <xsl:value-of select="$position"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$position"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

      <!-- Depuration code -->
    <xsl:message>
      <xsl:text>SCRIPT is </xsl:text>
      <xsl:value-of select="concat($order,'-z-',$filename)"/>
      <xsl:text>&#xA;    FTPDIR is </xsl:text>
      <xsl:value-of select="$filename"/>
      <xsl:text>&#xA;&#xA;</xsl:text>
    </xsl:message>

      <!-- Creating the scripts -->
    <exsl:document href="{$order}-z-{$filename}" method="text">
      <xsl:text>#!/bin/bash
set -e
# Variables coming from configuration
export JH_PACK_INSTALL="</xsl:text>
      <xsl:copy-of select="$pack-install"/>
      <xsl:text>"
export JH_SRC_ARCHIVE="</xsl:text>
      <xsl:copy-of select="$src-archive"/>
      <xsl:text>"
export JH_SRC_SUBDIRS="</xsl:text>
      <xsl:copy-of select="$src-subdirs"/>
      <xsl:text>"
export JH_BUILD_ROOT="</xsl:text>
      <xsl:copy-of select="$build-root"/>
      <xsl:text>"
export JH_BUILD_SUBDIRS="</xsl:text>
      <xsl:copy-of select="$build-subdirs"/>
      <xsl:text>"
export JH_KEEP_FILES="</xsl:text>
      <xsl:copy-of select="$keep-files"/>
      <xsl:text>"
</xsl:text>
      <xsl:choose>
        <xsl:when test="$cfg-cflags = 'EMPTY'">
          <xsl:text>unset CFLAGS
</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>export CFLAGS="</xsl:text>
          <xsl:copy-of select="$cfg-cflags"/>
          <xsl:text>"
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="$cfg-cxxflags = 'EMPTY'">
          <xsl:text>unset CXXFLAGS
</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>export CXXFLAGS="</xsl:text>
          <xsl:copy-of select="$cfg-cxxflags"/>
          <xsl:text>"
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="$cfg-ldflags = 'EMPTY'">
          <xsl:text>unset LDFLAGS
</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>export LDFLAGS="</xsl:text>
          <xsl:copy-of select="$cfg-ldflags"/>
          <xsl:text>"
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
<!-- We use MAKEFLAGS and NINJAJOBS for setting the number of
     parallel jobs. This supposes that ninja has been build with
     support for NINJAJOBS in lfs. We'll have to change that code
     if lfs changes its policy for ninja. -->
      <xsl:text>export MAKEFLAGS="-j</xsl:text>
      <xsl:choose>
        <xsl:when test="$jobs = 0">
          <xsl:text>$(nproc)"
</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$jobs"/>
          <xsl:text>"
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="$jobs = 0">
          <xsl:text>unset NINJAJOBS
</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>export NINJAJOBS="</xsl:text>
          <xsl:value-of select="$jobs"/>
          <xsl:text>"
</xsl:text>
       </xsl:otherwise>
     </xsl:choose>
<!-- Unsetting MAKELEVEL is needed for some packages which assume that
     their top level Makefile is at level zero.
     Some packages (cmake) use MAKE_TERMOUT and MAKE_TERMERR to determine
     whether they are talking to a terminal.
     In our case, stdout/stderr are always redirected, so unset them.-->
     <xsl:text>unset MAKELEVEL
unset MAKE_TERMOUT
unset MAKE_TERMERR
<!-- When installing several packages, and profile or profile.d
     has been modified by a previous package, we need to ensure that
     the updated profile is used.
-->if [ -r /etc/profile ]; then source /etc/profile; fi
# End of environment</xsl:text>

      <xsl:choose>
        <!-- Package page -->
        <xsl:when test="sect2[@role='package']">
          <!-- We build in a subdirectory, whose name may be needed
               if using package management, so
               "export" it -->
          <xsl:text>
export JH_PKG_DIR=</xsl:text>
          <xsl:value-of select="$filename"/>
          <xsl:text>
SRC_DIR=${JH_SRC_ARCHIVE}${JH_SRC_SUBDIRS:+/${JH_PKG_DIR}}
BUILD_DIR=${JH_BUILD_ROOT}${JH_BUILD_SUBDIRS:+/${JH_PKG_DIR}}
mkdir -p $SRC_DIR
mkdir -p $BUILD_DIR
</xsl:text>

<!-- If stats are requested, include some definitions and initializations -->
          <xsl:if test="$want-stats">
            <xsl:text>
INFOLOG=$(pwd)/info-${JH_PKG_DIR}
TESTLOG=$(pwd)/test-${JH_PKG_DIR}
echo MAKEFLAGS: $MAKEFLAGS >  $INFOLOG
echo NINJAJOBS: $NINJAJOBS >> $INFOLOG
: > $TESTLOG
PKG_DEST=${BUILD_DIR}/dest
</xsl:text>
<!-- in some cases, DESTDIR may have been populated by root -->
            <xsl:if test="$sudo = 'y'">
              <xsl:text>sudo </xsl:text>
            </xsl:if>
            <xsl:text>rm -rf $PKG_DEST
</xsl:text>
          </xsl:if><!-- want-stats -->
        <!-- Download code and build commands -->
          <xsl:apply-templates select="sect2">
            <xsl:with-param name="want-stats" select="$want-stats"/>
          </xsl:apply-templates>
        <!-- Clean-up -->
          <xsl:text>

cd $BUILD_DIR
[[ -n "$JH_KEEP_FILES" ]] || </xsl:text>
        <!-- In some case, some files in the build tree are owned
             by root -->
          <xsl:if test="$sudo='y'">
            <xsl:text>sudo </xsl:text>
          </xsl:if>
          <xsl:text>rm -rf $JH_UNPACKDIR unpacked
</xsl:text>
        </xsl:when>
      <!-- Non-package page -->
        <xsl:otherwise>
          <xsl:apply-templates select=".//screen" mode="not-pack"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>
exit
</xsl:text><!-- include a \n at the end of document-->
    </exsl:document>
  </xsl:template>

<!--======================= Sub-sections code =======================-->

  <xsl:template match="sect2">
    <xsl:param name="want-stats" select="false"/>
    <xsl:choose>

      <xsl:when test="@role = 'package'">
        <xsl:text>
cd $SRC_DIR</xsl:text>
        <!-- Download information is in bridgehead tags -->
        <xsl:apply-templates select="bridgehead[@renderas='sect3']"/>
      </xsl:when><!-- @role="package" -->

      <xsl:when test="@role = 'qt5-prefix' or @role = 'qt6-prefix'">
        <xsl:apply-templates select=".//screen[./userinput]"/>
      </xsl:when>

      <xsl:when test="@role = 'installation' and
                      not(preceding-sibling::sect2[@role = 'installation'])">
        <xsl:text>
cd $BUILD_DIR
find . -maxdepth 1 -mindepth 1 -type d | xargs </xsl:text>
        <xsl:if test="$sudo='y'">
          <xsl:text>sudo </xsl:text>
        </xsl:if>
        <xsl:text>rm -rf
</xsl:text>
        <!-- If stats are requested, insert the start size -->
        <xsl:if test="$want-stats">
          <xsl:text>
echo Start Size: $(sudo du -skx --exclude home $BUILD_DIR) >> $INFOLOG
</xsl:text>
        </xsl:if>

        <xsl:text>
case $PACKAGE in
  *.tar.gz|*.tar.bz2|*.tar.xz|*.tgz|*.tar.lzma)
     tar -xvf $SRC_DIR/$PACKAGE &gt; unpacked
     JH_UNPACKDIR=`grep '[^./]\+' unpacked | head -n1 | sed 's@^\./@@;s@/.*@@'`
     ;;
  *.tar.lz)
     bsdtar -xvf $SRC_DIR/$PACKAGE 2&gt; unpacked
     JH_UNPACKDIR=`head -n1 unpacked | cut  -d" " -f2 | sed 's@^\./@@;s@/.*@@'`
     ;;
  *.zip)
     zipinfo -1 $SRC_DIR/$PACKAGE &gt; unpacked
     JH_UNPACKDIR="$(sed 's@/.*@@' unpacked | uniq )"
     if test $(wc -w &lt;&lt;&lt; $JH_UNPACKDIR) -eq 1; then
       unzip $SRC_DIR/$PACKAGE
     else
       JH_UNPACKDIR=${PACKAGE%.zip}
       unzip -d $JH_UNPACKDIR $SRC_DIR/$PACKAGE
     fi
     ;;
  *)
     JH_UNPACKDIR=$JH_PKG_DIR-build
     mkdir $JH_UNPACKDIR
     cp $SRC_DIR/$PACKAGE $JH_UNPACKDIR
     ADDITIONAL="$(find . -mindepth 1 -maxdepth 1 -type l)"
     if [ -n "$ADDITIONAL" ]; then
         cp $ADDITIONAL $JH_UNPACKDIR
     fi
     ;;
esac
export JH_UNPACKDIR
cd $JH_UNPACKDIR
</xsl:text>
        <!-- If stats are requested, insert the start time -->
        <xsl:if test="$want-stats">
          <xsl:text>
echo Start Time: ${SECONDS} >> $INFOLOG
</xsl:text>
        </xsl:if>

        <xsl:call-template name="process-install">
          <xsl:with-param
             name="instruction-tree"
             select=".//screen[not(@role = 'nodump') and ./userinput] |
                     .//para/command[contains(text(),'check') or
                                     contains(text(),'test')]"/>
          <xsl:with-param name="want-stats" select="$want-stats"/>
          <xsl:with-param name="root-seen" select="boolean(0)"/>
          <xsl:with-param name="install-seen" select="boolean(0)"/>
          <xsl:with-param name="test-seen" select="boolean(0)"/>
          <xsl:with-param name="doc-seen" select="boolean(0)"/>
        </xsl:call-template>
        <xsl:text>
</xsl:text>
        <xsl:if test="$sudo = 'y'">
          <xsl:text>sudo /sbin/</xsl:text>
        </xsl:if>
        <xsl:text>ldconfig</xsl:text>
      </xsl:when><!-- @role="installation" -->

      <xsl:when test="@role = 'configuration'">
        <xsl:text>&#xA;</xsl:text>
        <xsl:apply-templates mode="config"
             select=".//screen[not(@role = 'nodump') and ./userinput]"/>
      </xsl:when><!-- @role="configuration" -->

    </xsl:choose>
  </xsl:template>

<!--==================== Download code =======================-->

  <!-- template for extracting the filename from an url in the form:
       proto://internet.name/dir1/.../dirn/filename?condition.
       Needed, because substring-after(...,'/') returns only the
       substring after the first '/'. -->
  <xsl:template name="package_name">
    <xsl:param name="url" select="foo"/>
    <xsl:param name="sub-url" select="substring-after($url,'/')"/>
    <xsl:choose>
      <xsl:when test="contains($sub-url,'/')">
        <xsl:call-template name="package_name">
          <xsl:with-param name="url" select="$sub-url"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($sub-url,'?')">
            <xsl:value-of select="substring-before($sub-url,'?')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$sub-url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Generates the code to download a package, an additional package or
       a patch. -->
  <xsl:template name="download-file">
    <xsl:param name="httpurl" select="''"/>
    <xsl:param name="ftpurl" select="''"/>
    <xsl:param name="md5" select="''"/>
    <xsl:param name="varname" select="''"/>
    <xsl:variable name="package">
      <xsl:call-template name="package_name">
        <xsl:with-param name="url">
          <xsl:choose>
            <xsl:when test="string-length($httpurl) &gt; 10">
              <xsl:value-of select="$httpurl"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ftpurl"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>=</xsl:text>
    <xsl:value-of select="$package"/>
    <xsl:text>&#xA;if [[ ! -f $</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> ]] ; then
  if [ -f "$JH_SRC_ARCHIVE/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>" ] ; then&#xA;</xsl:text>
    <xsl:text>    cp "$JH_SRC_ARCHIVE/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>" "$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>"
  else<!-- Download from upstream http -->
    wget -T 30 -t 5 "</xsl:text>
    <xsl:value-of select="$httpurl"/>
    <xsl:text>"
  fi
fi</xsl:text>
    <xsl:if test="string-length($md5) &gt; 10">
      <xsl:text>
echo "</xsl:text>
      <xsl:value-of select="$md5"/>
      <xsl:text>&#x20;&#x20;$</xsl:text>
      <xsl:value-of select="$varname"/>
      <xsl:text>" | md5sum -c -</xsl:text>
    </xsl:if>
<!-- link additional packages into $BUILD_DIR, because they are supposed to
     be there-->
    <xsl:if test="string($varname) != 'PACKAGE'">
      <xsl:text>
[ "$SRC_DIR" != "$BUILD_DIR" ] &amp;&amp; ln -sf "$SRC_DIR/$</xsl:text>
      <xsl:value-of select="$varname"/>
      <xsl:text>" "$BUILD_DIR"</xsl:text>
    </xsl:if>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <!-- Extract the MD5 sum information -->
  <xsl:template match="para" mode="md5">
    <xsl:choose>
      <xsl:when test="contains(substring-after(string(),'sum: '),'&#xA;')">
        <xsl:value-of select="substring-before(substring-after(string(),'sum: '),'&#xA;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-after(string(),'sum: ')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- We have several templates itemizedlist, depending on whether we
       expect the package information, or additional package(s) or patch(es)
       information. Select the appropriate mode here. -->
  <xsl:template match="bridgehead">
    <xsl:choose>
      <!-- Special case for Openjdk -->
      <xsl:when test="contains(string(),'Source Package Information')">
        <xsl:apply-templates
             select="following-sibling::itemizedlist[1]//simplelist">
          <xsl:with-param name="varname" select="'PACKAGE'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="following-sibling::itemizedlist
                             [preceding-sibling::bridgehead[1]=current()
                              and position() &gt;1]//simplelist">
          <xsl:with-param name="varname" select="'PACKAGE1'"/>
        </xsl:apply-templates>
      </xsl:when>
      <!-- Package information -->
      <xsl:when test="contains(string(),'Package Information')">
        <xsl:apply-templates select="following-sibling::itemizedlist
                             [preceding-sibling::bridgehead[1]=current()]"
                             mode="package"/>
      </xsl:when>
      <!-- Additional package information -->
      <!-- special cases for llvm -->
      <xsl:when test="contains(string(),'Recommended Download')">
        <xsl:apply-templates select="following-sibling::itemizedlist
                             [preceding-sibling::bridgehead[1]=current()]"
                             mode="additional"/>
      </xsl:when>
      <xsl:when test="contains(string(),'Optional Download')">
        <xsl:apply-templates select="following-sibling::itemizedlist
                             [preceding-sibling::bridgehead[1]=current()]"
                             mode="additional"/>
      </xsl:when>
      <!-- All other additional packages have "Additional" -->
      <xsl:when test="contains(string(),'Additional')">
        <xsl:apply-templates select="following-sibling::itemizedlist
                             [preceding-sibling::bridgehead[1]=current()]"
                             mode="additional"/>
      </xsl:when>
      <!-- Do not do anything if the dev has created another type of
           bridgehead. -->
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <!-- Call the download code template with appropriate parameters -->
  <xsl:template match="itemizedlist" mode="package">
    <xsl:call-template name="download-file">
      <xsl:with-param name="httpurl">
        <xsl:value-of select="./listitem[1]/para/ulink/@url"/>
      </xsl:with-param>
      <xsl:with-param name="ftpurl">
        <xsl:value-of select="./listitem/para[contains(string(),'FTP')]/ulink/@url"/>
      </xsl:with-param>
      <xsl:with-param name="md5">
        <xsl:apply-templates select="./listitem/para[contains(string(),'MD5')]"
                             mode="md5"/>
      </xsl:with-param>
      <xsl:with-param name="varname" select="'PACKAGE'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="itemizedlist" mode="additional">
  <!-- The normal layout is "one listitem"<->"one url", but some devs
       find amusing to have FTP and/or MD5sum listitems, or to
       enclose the download information inside a simplelist tag... -->
    <xsl:for-each select="listitem[.//ulink]">
      <xsl:choose>
        <!-- hopefully, there was a HTTP line before -->
        <xsl:when test="contains(string(./para),'FTP')"/>
        <xsl:when test=".//simplelist">
          <xsl:apply-templates select=".//simplelist">
            <xsl:with-param name="varname" select="'PACKAGE1'"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="download-file">
            <xsl:with-param name="httpurl">
              <xsl:value-of select="./para/ulink/@url"/>
            </xsl:with-param>
            <xsl:with-param name="ftpurl">
              <xsl:value-of
                   select="following-sibling::listitem[1]/
                           para[contains(string(),'FTP')]/ulink/@url"/>
            </xsl:with-param>
            <xsl:with-param name="md5">
              <xsl:apply-templates
                   select="following-sibling::listitem[position()&lt;3]/
                           para[contains(string(),'MD5')]"
                   mode="md5"/>
            </xsl:with-param>
            <xsl:with-param name="varname">
              <xsl:choose>
                <xsl:when test="contains(./para/ulink/@url,'.patch')">
                  <xsl:text>PATCH</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>PACKAGE1</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- the simplelist case. Hopefully, the layout is one member for
       url, one for md5 and others for various information, that we do not
       use -->
  <xsl:template match="simplelist">
    <xsl:param name="varname" select="'PACKAGE1'"/>
    <xsl:call-template name="download-file">
      <xsl:with-param name="httpurl" select=".//ulink/@url"/>
      <xsl:with-param name="md5">
        <xsl:value-of select="substring-after(member[contains(string(),'MD5')],'sum: ')"/>
      </xsl:with-param>
      <xsl:with-param name="varname" select="$varname"/>
    </xsl:call-template>
  </xsl:template>

<!--====================== Non package code =========================-->

  <xsl:template match="screen" mode="not-pack">
    <xsl:choose>
      <xsl:when test="@role='nodump'"/>
      <xsl:when test="ancestor::sect1[@id='postlfs-config-vimrc']">
        <xsl:text>
cat > ~/.vimrc &lt;&lt;EOF
</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>
EOF
</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="config"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
<!--======================== Commands code ==========================-->
<!-- Code for installation instructions is in gen-install.xsl -->

  <xsl:template match="screen">
    <xsl:choose>
<!-- instructions run as root (configuration mainly) -->
      <xsl:when test="@role = 'root'">
<!-- templates begin/end-root are in gen-install.xsl -->
        <xsl:if test="not(preceding-sibling::screen[1][@role='root'])">
          <xsl:call-template name="begin-root"/>
        </xsl:if>
        <xsl:apply-templates mode="root"/>
        <xsl:if test="not(following-sibling::screen[1][@role='root'])">
          <xsl:call-template name="end-root"/>
        </xsl:if>
      </xsl:when>
<!-- then all the instructions run as user -->
      <xsl:otherwise>
        <xsl:apply-templates select="userinput"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- Templates for bootscripts/units installation -->
  <xsl:template name="set-bootpkg-dir">
    <xsl:param name="bootpkg" select="'bootscripts'"/>
    <xsl:param name="url" select="''"/>
    <xsl:text>
BOOTPKG_DIR=blfs-</xsl:text>
    <xsl:copy-of select="$bootpkg"/>
    <xsl:text>

BOOTSRC_DIR=${JH_SRC_ARCHIVE}${JH_SRC_SUBDIRS:+/${BOOTPKG_DIR}}
BOOTBUILD_DIR=${JH_BUILD_ROOT}${JH_BUILD_SUBDIRS:+/${BOOTPKG_DIR}}
mkdir -p $BOOTSRC_DIR
mkdir -p $BOOTBUILD_DIR

pushd $BOOTSRC_DIR
URL=</xsl:text>
      <xsl:value-of select="$url"/>
    <xsl:text>
BOOTPACKG=$(basename $URL)
if [[ ! -f $BOOTPACKG ]] ; then
  if [[ -f $JH_SRC_ARCHIVE/$BOOTPACKG ]] ; then
    cp $JH_SRC_ARCHIVE/$BOOTPACKG $BOOTPACKG
  else
    wget -T 30 -t 5 $URL
  fi
  rm -f $BOOTBUILD_DIR/unpacked
fi

cd $BOOTBUILD_DIR
if [[ -e unpacked ]] ; then
  BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  if ! [[ -d $BOOTUNPACKDIR ]]; then
    tar -xvf $BOOTSRC_DIR/$BOOTPACKG > unpacked
    BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  fi
else
  tar -xvf $BOOTSRC_DIR/$BOOTPACKG > unpacked
  BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
fi
cd $BOOTUNPACKDIR</xsl:text>
  </xsl:template>

  <xsl:template match="screen" mode="config">
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='bootscripts']">
<!-- if the preceding "screen" tag is role="root", and we are role="root"
     the end-root has not been called, except if the preceding "screen"
     tag is itself preceded by a <para> containing and <xref> to
     bootscripts. So close it only if needed -->
      <xsl:if
        test="preceding-sibling::screen[1][@role='root'] and
        @role='root' and
        not(preceding-sibling::screen[1]/preceding-sibling::para[1]/xref[@linkend='bootscripts'])">
        <xsl:call-template name="end-root"/>
      </xsl:if>
      <xsl:call-template name="set-bootpkg-dir">
        <xsl:with-param name="bootpkg" select="'bootscripts'"/>
        <xsl:with-param name="url"
                        select="id('bootscripts')//itemizedlist//ulink/@url"/>
      </xsl:call-template>
<!-- if the preceding "screen" tag is role="root", and we are role="root"
     the begin-root will not be called. So do it.-->
      <xsl:if
        test="preceding-sibling::screen[1][@role='root'] and
        @role='root'">
        <xsl:call-template name="begin-root"/>
      </xsl:if>
    </xsl:if>
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='systemd-units']">
<!-- if the preceding "screen" tag is role="root", and we are role="root"
     the end-root has not been called. So do it, except if it was already a
     unit install -->
      <xsl:if
        test="preceding-sibling::screen[1][@role='root'] and
        @role='root' and
        not(preceding-sibling::screen[1]/preceding-sibling::para[1]/xref[@linkend='systemd-units'])">
        <xsl:call-template name="end-root"/>
      </xsl:if>
      <xsl:call-template name="set-bootpkg-dir">
        <xsl:with-param name="bootpkg" select="'systemd-units'"/>
        <xsl:with-param name="url"
                        select="id('systemd-units')//itemizedlist//ulink/@url"/>
      </xsl:call-template>
<!-- if the preceding "screen" tag is role="root", and we are role="root"
     the begin-root will not be called. So do it. -->
      <xsl:if
        test="preceding-sibling::screen[1][@role='root'] and
        @role='root'">
        <xsl:call-template name="begin-root"/>
      </xsl:if>
    </xsl:if>
    <xsl:apply-templates select='.'/>
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='bootscripts' or
                                                  @linkend='systemd-units']">
<!-- if the next "screen" tag is role="root", and we are role="root"
     the end-root has not been called. -->
      <xsl:if
           test="following-sibling::screen[1][@role='root'] and @role='root'">
        <xsl:call-template name="end-root"/>
      </xsl:if>
      <xsl:text>
popd</xsl:text>
<!-- if the next "screen" tag is role="root", and we are role="root"
     the begin-root will not be called. So do it, except if the next
     <screen> is itself a unit or bootscript install -->
      <xsl:if
        test="following-sibling::screen[1][@role='root'] and
        @role='root' and
        not(following-sibling::screen[1]/preceding-sibling::para[1]/xref[@linkend='bootscripts' or @linkend='systemd-units'])">
        <xsl:call-template name="begin-root"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="command" mode="installation">
    <xsl:param name="want-stats" select="false"/>
    <xsl:variable name="ns" select="normalize-space(string())"/>
    <xsl:variable name="first"
         select="not(
                   boolean(
                     preceding-sibling::command[contains(text(),'check') or
                                                contains(text(),'test')]))"/>
    <xsl:variable name="last"
         select="not(
                   boolean(
                     following-sibling::command[contains(text(),'check') or
                                                contains(text(),'test')]))"/>
    <xsl:choose>
      <xsl:when test="$want-stats">
        <xsl:if test="$first">
          <xsl:text>

echo Time after make: ${SECONDS} >> $INFOLOG
echo Size after make: $(sudo du -skx --exclude home $BUILD_DIR) >> $INFOLOG
echo Time before test: ${SECONDS} >> $INFOLOG

</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
#</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="contains($ns,'make')">
        <xsl:value-of select="substring-before($ns,'make ')"/>
        <xsl:text>make </xsl:text>
        <xsl:if test="not(contains($ns,'-k'))">
          <xsl:text>-k </xsl:text>
        </xsl:if>
        <xsl:value-of select="substring-after($ns,'make ')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$ns"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$want-stats">
      <xsl:text> &gt;&gt; $TESTLOG 2&gt;&amp;1</xsl:text>
    </xsl:if>
    <xsl:text> || true</xsl:text>
    <xsl:if test="$want-stats">
        <xsl:text>

echo Time after test: ${SECONDS} >> $INFOLOG
echo Size after test: $(sudo du -skx --exclude home $BUILD_DIR) >> $INFOLOG
echo Time before install: ${SECONDS} >> $INFOLOG
</xsl:text>
        </xsl:if>
  </xsl:template>

  <xsl:template match="userinput|command">
    <xsl:text>
</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="userinput" mode="root">
    <xsl:text>
</xsl:text>
    <xsl:apply-templates mode="root"/>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:call-template name="remove-ampersand">
      <xsl:with-param name="out-string" select="string()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="text()" mode="root">
    <xsl:call-template name="output-root">
      <xsl:with-param name="out-string" select="string()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="output-root">
    <xsl:param name="out-string" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($out-string,'$') and $sudo = 'y'">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'$')"/>
        </xsl:call-template>
        <xsl:text>\$</xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'$')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($out-string,'`') and $sudo = 'y'">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'`')"/>
        </xsl:call-template>
        <xsl:text>\`</xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'`')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($out-string,'\') and $sudo = 'y'">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'\')"/>
        </xsl:call-template>
        <xsl:text>\\</xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'\')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="remove-ampersand">
          <xsl:with-param name="out-string" select="$out-string"/>
        </xsl:call-template>
<!--        <xsl:value-of select="$out-string"/> -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="output-destdir">
    <xsl:apply-templates
       select="userinput|following-sibling::screen[@role='root']/userinput"
       mode="destdir"/>
    <xsl:text>

echo Time after install: ${SECONDS} >> $INFOLOG
echo Size after install: $(sudo du -skx --exclude home $BUILD_DIR) >> $INFOLOG
</xsl:text>
  </xsl:template>

  <xsl:template match="userinput" mode="destdir">
    <xsl:text>
</xsl:text>
    <xsl:for-each select="./literal">
      <xsl:call-template name="outputpkgdest">
        <xsl:with-param name="outputstring" select="preceding-sibling::text()[1]"/>
      </xsl:call-template>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
    <xsl:call-template name="outputpkgdest">
      <xsl:with-param name="outputstring" select="text()[last()]"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="outputpkgdest">
    <xsl:param name="outputstring" select="'foo'"/>
    <xsl:choose>
      <xsl:when test="contains(normalize-space($outputstring),' make ') or
                      starts-with($outputstring, 'make ')">
        <xsl:choose>
          <xsl:when test="not(starts-with($outputstring,'make'))">
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring"
                              select="substring-before($outputstring,'make')"/>
            </xsl:call-template>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param
                 name="outputstring"
                 select="substring-after($outputstring,
                                      substring-before($outputstring,'make'))"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>
make DESTDIR=$PKG_DEST</xsl:text>
              <xsl:call-template name="outputpkgdest">
                <xsl:with-param
                    name="outputstring"
                    select="substring-after($outputstring,'make')"/>
              </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains($outputstring,'ninja install')">
        <xsl:choose>
          <xsl:when test="not(starts-with($outputstring,'ninja install'))">
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring"
                              select="substring-before($outputstring,'ninja install')"/>
            </xsl:call-template>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param
                 name="outputstring"
                 select="substring-after($outputstring,
                                      substring-before($outputstring,'ninja install'))"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>
DESTDIR=$PKG_DEST ninja</xsl:text>
              <xsl:call-template name="outputpkgdest">
                <xsl:with-param
                    name="outputstring"
                    select="substring-after($outputstring,'ninja')"/>
              </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise> <!-- no make nor ninja in this string -->
        <xsl:choose>
          <xsl:when test="contains($outputstring,'&gt;/') and
                                 not(contains(substring-before($outputstring,'&gt;/'),' /'))">
            <xsl:call-template name="remove-ampersand">
              <xsl:with-param name="out-string"
                   select="substring-before($outputstring,'&gt;/')"/>
            </xsl:call-template>
<!--            <xsl:value-of select="substring-before($outputstring,'&gt;/')"/>-->
            <xsl:text>&gt;$PKG_DEST/</xsl:text>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring" select="substring-after($outputstring,'&gt;/')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="contains($outputstring,' /')">
            <xsl:call-template name="remove-ampersand">
              <xsl:with-param name="out-string"
                   select="substring-before($outputstring,' /')"/>
            </xsl:call-template>
<!--            <xsl:value-of select="substring-before($outputstring,' /')"/>-->
            <xsl:text> $PKG_DEST/</xsl:text>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring" select="substring-after($outputstring,' /')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="remove-ampersand">
              <xsl:with-param name="out-string" select="$outputstring"/>
            </xsl:call-template>
<!--            <xsl:value-of select="$outputstring"/>-->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="remove-ampersand">
    <xsl:param name="out-string" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($out-string,'&amp;&amp;&#xA;')">
        <xsl:variable name="instruction-before">
          <xsl:call-template name="last-line">
            <xsl:with-param
                 name="instructions"
                 select="substring-before($out-string,'&amp;&amp;&#xA;')"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="remove-end-space">
              <xsl:with-param
                 name="instructions"
                 select="substring-before($out-string,'&amp;&amp;&#xA;')"/>
        </xsl:call-template>
        <xsl:if test="contains($instruction-before,' ]') or
                      contains($instruction-before,'test ') or
                      contains($instruction-before,'pgrep -l')">
          <xsl:text> &amp;&amp;</xsl:text>
        </xsl:if>
        <xsl:text>
</xsl:text>
        <xsl:call-template name="remove-ampersand">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,
                                                  '&amp;&amp;&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$out-string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="last-line">
    <xsl:param name="instructions" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($instructions,'&#xA;')">
        <xsl:call-template name="last-line">
          <xsl:with-param
               name="instructions"
               select="substring-after($instructions,'&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="normalize-space($instructions)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="remove-end-space">
    <xsl:param name="instructions" select="''"/>
    <xsl:choose>
      <xsl:when
           test="substring($instructions,string-length($instructions))=' '">
        <xsl:call-template name="remove-end-space">
          <xsl:with-param
               name="instructions"
               select="substring($instructions,
                                 1,
                                 string-length($instructions)-1)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$instructions"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
