<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:text>#!/bin/bash
</xsl:text>
    <xsl:apply-templates select="//userinput[contains(string(),'--bind') or
                                             contains(string(),'/proc') or
                                             contains(string(),'readlink') or
                                             contains(string(),'-Rv')]"/>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:call-template name="check-mount">
      <xsl:with-param name="mytext" select="string()"/>
    </xsl:call-template>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template name="check-mount">
    <xsl:param name="mytext" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($mytext,'&#xA;')">
        <xsl:call-template name="check-mount">
          <xsl:with-param name="mytext"
                          select="substring-before($mytext,'&#xA;')"/>
        </xsl:call-template>
        <xsl:text>&#xA;</xsl:text>
        <xsl:call-template name="check-mount">
          <xsl:with-param name="mytext"
                          select="substring-after($mytext,'&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="starts-with(normalize-space($mytext),'mountpoint')">
        <xsl:copy-of select="$mytext"/>
      </xsl:when>
      <xsl:when test="starts-with(normalize-space($mytext),'mount')">
        <xsl:variable name="mountpoint">
          <xsl:call-template name="last-arg">
            <xsl:with-param name="myline" select="$mytext"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:text>mountpoint -q </xsl:text>
        <xsl:copy-of select="$mountpoint"/>
        <xsl:text> || </xsl:text>
        <xsl:copy-of select="$mytext"/>
      </xsl:when>
      <xsl:when test="starts-with(normalize-space($mytext),'umount')">
        <xsl:variable name="mountpoint">
          <xsl:call-template name="last-arg">
            <xsl:with-param name="myline" select="$mytext"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:text>mountpoint -q </xsl:text>
        <xsl:copy-of select="$mountpoint"/>
        <xsl:text> &amp;&amp; </xsl:text>
        <xsl:copy-of select="$mytext"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$mytext"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="last-arg">
    <xsl:param name="myline" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($myline,' ')">
        <xsl:call-template name="last-arg">
          <xsl:with-param name="myline" select="substring-after($myline,' ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$myline"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
