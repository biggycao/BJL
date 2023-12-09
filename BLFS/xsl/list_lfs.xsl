<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:text>bootscripts </xsl:text>
    <xsl:text>lfs-bootscripts </xsl:text>
    <xsl:text>kernel </xsl:text>
    <xsl:text>porg </xsl:text>
    <xsl:text>tzdata </xsl:text>
    <!-- the next two packages are not in LFS, but jhalfs needs them -->
    <xsl:text>sudo </xsl:text>
    <xsl:text>wget </xsl:text>
    <xsl:apply-templates select=".//chapter[@id='chapter-building-system']/sect1/sect1info/productname"/>
  </xsl:template>

  <xsl:template match="productname">
    <xsl:copy-of select="text()"/>
    <xsl:text> </xsl:text>
  </xsl:template>

</xsl:stylesheet>
