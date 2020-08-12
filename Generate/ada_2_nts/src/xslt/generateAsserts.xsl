<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:nts="http://nictiz.nl/xsl/testscript"
    xmlns:f="http://hl7.org/fhir"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <!--<xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>-->
    
    <xsl:output indent="yes"/>
    
    <xsl:template match="node()|@*" mode="#all" priority="-1">
        <xsl:apply-templates select="node()|@*" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="/">
        <nts:contentAsserts>
            <xsl:apply-templates mode="variables"/>
            <xsl:apply-templates mode="asserts"/>
        </nts:contentAsserts>
    </xsl:template>
    
    <xsl:template name="create-resourceID">
        <xsl:text>resource-no-</xsl:text>
        <xsl:value-of select="count(parent::f:resource/parent::f:entry/preceding-sibling::f:entry[f:search/f:mode/@value='match']/f:resource/f:*)+1"/>
    </xsl:template>
    
    <!-- search mode match moet er zijn!? -->
    <xsl:template match="f:entry[f:search/f:mode/@value='match']/f:resource/f:*" mode="variables">
        <!-- Edge cases:
            - Wat als de variabele niets kan vinden?
            - Wat als (door een foutje van de leverancier) er 2 resultaten zijn?
        -->
        <xsl:variable name="uniqueContents" select="'dosageInstruction.dose.value = 2 and dosageInstruction.timing.repeat.frequency = 1'"/>
        <xsl:variable name="resourceID">
            <xsl:call-template name="create-resourceID"/>
        </xsl:variable>
        <f:variable>
            <f:name value="{$resourceID}"/>
            <f:expression value="Bundle.entry.select(resource as {local-name()}).where({$uniqueContents}).id"/>
            <f:sourceId value="response"/>
        </f:variable>
    </xsl:template>
    
    <!-- Exclusions -->
    <xsl:template match="f:entry/f:fullUrl" mode="asserts"/>
    <xsl:template match="f:entry/f:resource/f:*/f:meta" mode="asserts"/>
    <xsl:template match="f:entry/f:resource/f:*/f:text" mode="asserts"/>
    <xsl:template match="f:entry/f:search" mode="asserts"/>
    
    <xsl:template match="@value[ancestor::f:entry/f:search/f:mode/@value='match']" mode="asserts">
        <xsl:variable name="expression">
            <!--<xsl:value-of select="'Bundle.entry.select(resource as MedicationRequest).where(id = ''${scenario-0-1-ma-1}'').medication.display.contains('''"/>-->
            <xsl:for-each select="ancestor::*">
                <!--<xsl:sort select="position()" data-type="number" order="ascending"/>-->
                <xsl:choose>
                    <xsl:when test="self::f:resource"/>
                    <xsl:when test="self::f:*[parent::f:resource]">
                        <xsl:text>.</xsl:text>
                        <xsl:text>select(resource as </xsl:text>
                        <xsl:value-of select="local-name()"/>
                        <xsl:text>).where(id = '${</xsl:text>
                        <xsl:call-template name="create-resourceID"/>
                        <xsl:text>}')</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="baseElement">
                            <xsl:choose>
                                <!-- Kopiëren uit NarrativeGenerator -->
                                <xsl:when test="ends-with(local-name(),'Identifier')">
                                    <xsl:value-of select="substring-before(local-name(),'Identifier')"/>
                                </xsl:when>
                                <xsl:when test="ends-with(local-name(),'Period')">
                                    <xsl:value-of select="substring-before(local-name(),'Period')"/>
                                </xsl:when>
                                <xsl:when test="ends-with(local-name(),'Quantity')">
                                    <xsl:value-of select="substring-before(local-name(),'Quantity')"/>
                                </xsl:when>
                                <xsl:when test="ends-with(local-name(),'Reference')">
                                    <xsl:value-of select="substring-before(local-name(),'Reference')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="local-name()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:if test="not(self::f:Bundle)">
                            <xsl:text>.</xsl:text>
                        </xsl:if>
                        <xsl:value-of select="$baseElement"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <!--<xsl:choose>
                <!-\-<xsl:when test="starts-with(.,'${DATE, T')">
                    <!-\\- Check if conforms to datetime format? -\\->
                    <!-\\- exists? -\\->
                </xsl:when>-\->
                <!-\- Check if integer? -\->
                <xsl:otherwise>-->
                    <xsl:text>.contains('</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>')</xsl:text>
                <!--</xsl:otherwise>
            </xsl:choose>-->
        </xsl:variable>
        <f:action>
            <f:assert>
                <f:description value="..."/>
                <f:expression value="{$expression}"/>
            </f:assert>
        </f:action>
    </xsl:template>
    
</xsl:stylesheet>