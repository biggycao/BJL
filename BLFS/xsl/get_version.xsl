<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"/>

  <xsl:param name="package" select="'gcc'"/>

  <xsl:key name="depnode"
           match="package|module"
           use="name"/>

  <xsl:template match="/">
    <xsl:apply-templates select="key('depnode',$package)"/>
  </xsl:template>

  <xsl:template match="package|module">
    <xsl:value-of select="./version"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:choose>
      <xsl:when test="./inst-version">
        <xsl:value-of select="./inst-version"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>0</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
