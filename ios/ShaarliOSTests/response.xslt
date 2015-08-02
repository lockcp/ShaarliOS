<?xml version="1.0" encoding="UTF-8"?>
<!--

  This would be really nice to reduce the code-complexity of the (html) parser
  - if Apple wouldn't have chosen to consider libxslt a private API.
  http://stackoverflow.com/questions/7895157/applying-xslt-to-an-xml-coming-from-a-webservice-in-ios

  http://www.w3.org/TR/xslt

-->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="xsl"
    version="1.0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/">
    <shaarli>
      <xsl:for-each select="/html/body">
        <xsl:for-each select=".//span[@id = 'shaarli_title']">
          <xsl:attribute name="title">
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:attribute>
        </xsl:for-each>
        <xsl:for-each select="div[@id = 'pageheader']//a[@href = '?do=logout']">
          <is_logged_in value="true"/>
        </xsl:for-each>
        <xsl:for-each select="div[@id = 'pageheader']/div[@id='headerform' and 0 = count(*)]">
          <error>
            <xsl:attribute name="title">
              <xsl:value-of select="normalize-space(.)"/>
            </xsl:attribute>
          </error>
        </xsl:for-each>
        <xsl:for-each select=".//div[@id='headerform']//input">
          <xsl:copy-of select="."/>
        </xsl:for-each>
        <xsl:for-each select=".//div[@id = 'cloudtag']/span[@class = 'count']">
          <tag count="{.}">
            <xsl:for-each select="following-sibling::a[1]">
              <xsl:attribute name="href">
                <xsl:value-of select="@href"/>
              </xsl:attribute>
              <xsl:attribute name="title">
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:attribute>
            </xsl:for-each>
          </tag>
        </xsl:for-each>
      </xsl:for-each>
    </shaarli>
  </xsl:template>
</xsl:stylesheet>
