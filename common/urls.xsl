<?xml version='1.0' encoding='ISO-8859-1'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"/>

  <!-- Do we use a package manager? -->
  <xsl:param name="pkgmngt" select="'n'"/>

  <!-- The system for LFS: sysv of systemd -->
  <xsl:param name="revision" select="'sysv'"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//varlistentry[@revision=$revision
                                                or not(@revision)]//ulink"/>
    <xsl:if test="$pkgmngt='y'">
      <xsl:apply-templates
        select="document('packageManager.xml')//ulink"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ulink">
      <!-- If some package doesn't have the predefined strings in their
      name, the next test must be fixed to match it also. Skip possible
      duplicated URLs due that may be splitted for PDF output -->
    <xsl:if test="(contains(@url, '.bz2') or contains(@url, '.tar.gz') or
                  contains(@url, '.tgz') or contains(@url, '.patch') or
                  contains(@url, '.xz') or contains(@url, '.lzma')) and
                  not(ancestor-or-self::*/@condition = 'pdf')">
      <!-- Extract the package name -->
      <xsl:variable name="package">
        <xsl:call-template name="package.name">
          <xsl:with-param name="url" select="@url"/>
        </xsl:call-template>
      </xsl:variable>
      <!-- Write the upstream URLs, fixing the redirected ones -->
      <xsl:choose>
        <xsl:when test="contains(@url,'?')">
          <xsl:value-of select="substring-before(@url,'?')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@url"/>
        </xsl:otherwise>
      </xsl:choose>
      <!-- Write MD5SUM value -->
      <xsl:text> </xsl:text>
      <xsl:value-of select="../following-sibling::para/literal"/>
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="package.name">
    <xsl:param name="url"/>
    <xsl:choose>
      <xsl:when test="contains($url, '/') and not (substring-after($url,'/')='')">
        <xsl:call-template name="package.name">
          <xsl:with-param name="url" select="substring-after($url, '/')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($url, '?')">
            <xsl:value-of select="substring-before($url, '?')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
