<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:param name="packages" select="'packages.xml'"/>
  <xsl:param name="package" select="''"/>
  <xsl:param name="version" select="'N'"/>

  <xsl:variable name="realpackage">
    <xsl:choose>
      <xsl:when test="contains($package, '-pass1')">
        <xsl:copy-of select="substring-before($package, '-pass1')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$package"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="vers">
    <xsl:choose>
      <xsl:when test="$version='N'">
        <xsl:value-of select=
            "document($packages)//*[self::package or self::module]
                                   [string(name)=$realpackage]/version"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$version"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:output
    method="xml"
    encoding="ISO-8859-1"
    doctype-system="PACKDESC"/>

  <xsl:template match="/">
    <sublist>
      <xsl:copy-of select="./sublist/name"/>
      <xsl:apply-templates select=".//package"/>
      <xsl:if test="not(.//package[string(name)=$package])">
        <package>
          <name><xsl:copy-of select="$package"/></name>
          <version><xsl:copy-of select="$vers"/></version>
        </package>
      </xsl:if>
    </sublist>
  </xsl:template>

  <xsl:template match="package">
    <xsl:choose>
      <xsl:when test="string(name)=$package">
        <package>
          <name><xsl:copy-of select="$package"/></name>
          <version><xsl:copy-of select="$vers"/></version>
        </package>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select='.'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
