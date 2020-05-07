<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:nf="http://www.nictiz.nl/functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    
    <xsl:param name="targetSystem">xis</xsl:param>
    <xsl:param name="testFormat">xml</xsl:param>
    
    <xsl:variable name="scenarioId" select="/adaxml/data/*/@id"/>
    <xsl:variable name="partId">
        <xsl:choose>
            <xsl:when test="starts-with($scenarioId,'mg-mgr-mg-MA')">ma</xsl:when>
            <xsl:when test="starts-with($scenarioId,'mg-mgr-mg-VV')">vv</xsl:when>
            <xsl:when test="starts-with($scenarioId,'mo-mor-ma')">mo</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="longPartId">
        <xsl:choose>
            <xsl:when test="$partId='ma'">MedicationAgreement (NL: MedicatieAfspraak)</xsl:when>
            <xsl:when test="$partId='vv'">DispenseRequest (NL: VerstrekkingsVerzoek)</xsl:when>
            <xsl:when test="$partId='mo'">MedicationOverview (NL: MedicatieOverzicht)</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="partSnomedCategoryCode">
        <xsl:choose>
            <xsl:when test="$partId='ma'">16076005</xsl:when>
            <xsl:when test="$partId='vv'">52711000146108</xsl:when>
            <!-- MedicationOverview is retrieved with a Operation. No Snomedcode needed  -->
        </xsl:choose>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:variable name="description" select="adaxml/data/*/@desc"/>
        
        <nts:dummy xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript">
            <xsl:choose>
                <xsl:when test="$targetSystem='xis' and $partId='mo'"><!--Also usable for PHR?-->
                    <nts:include value="xis-mo-operation-post">
                        <nts:variable name="description" value="Test XIS server to serve {$longPartId} - {$description}"/>
                        <nts:variable name="accept" value="{$testFormat}"/>
                    </nts:include>
                    <!--<action>
                        <operation>
                            <type>
                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                <code value="search"/>
                            </type>
                            <description value="Test XIS server to serve {$longPartId} - {$description}"/>
                            <accept value="{$testFormat}"/>
                            <destination value="1"/>
                            <method value="post"/>
                            <origin value="1"/>
                            <params value="$medication-overview"/>
                            <requestHeader>
                                <field value="Authorization"/>
                                <value value="${{patient-token-id}}"/>
                            </requestHeader>
                        </operation>
                    </action>-->
                    <nts:include value="assert-responseBundleContent" scope="common"/>
                </xsl:when>
                <xsl:when test="$targetSystem='xis' and ($partId='ma' or 'vv')"><!--Also usable for PHR?-->
                    <nts:include value="xis-ma-vv-operation-search">
                        <nts:variable name="description" value="Test XIS server to serve {$longPartId} - {$description}"/>
                        <nts:variable name="accept" value="{$testFormat}"/>
                        <nts:variable name="params" value="?category=http://snomed.info/sct|{$partSnomedCategoryCode}&amp;_include=MedicationRequest:medication"/>
                    </nts:include>
                    <!--<action>
                        <operation>
                            <type>
                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                <code value="search"/>
                            </type>
                            <resource value="MedicationRequest"/>
                            <description value="Test XIS server to serve {$longPartId} - {$description}"/>
                            <accept value="{$testFormat}"/>
                            <destination value="1"/>
                            <origin value="1"/>
                            <params value="?category=http://snomed.info/sct|{$partSnomedCategoryCode}&amp;_include=MedicationRequest:medication"/>
                            <requestHeader>
                                <field value="Authorization"/>
                                <value value="${{patient-token-id}}"/>
                            </requestHeader>
                        </operation>
                    </action>-->
                    <nts:include value="assert-responseSearchBundleSuccess" scope="common"/>
                    <nts:include value="assert-responseBundleContent" scope="common"/>
                </xsl:when>
            </xsl:choose>         
                
            <xsl:if test="$partId=('ma','vv')">
                <xsl:variable name="returnCount" as="xs:integer">
                    <xsl:choose>
                        <xsl:when test="$partId='ma'">
                            <xsl:value-of select="count(adaxml/data/*/medicamenteuze_behandeling/medicatieafspraak)"/>
                        </xsl:when>
                        <xsl:when test="$partId='vv'">
                            <xsl:value-of select="count(adaxml/data/*/medicamenteuze_behandeling/verstrekkingsverzoek)"/>
                        </xsl:when>
                        <!--<xsl:when test="$partId='mo'">
                            <xsl:value-of select="count(adaxml/data/*/medicamenteuze_behandeling/*[name()=('medicatieafspraak','toedieningsafspraak','medicatiegebruik')])"/>
                        </xsl:when>-->
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="partIdEN">
                    <xsl:choose>
                        <xsl:when test="$partId='ma'">MedicationAgreement</xsl:when>
                        <xsl:when test="$partId='vv'">DispenseRequest</xsl:when>
                        <!--<xsl:when test="$partId='mo'">MedicationAgreement, MedicationUse, AdministrationAgreement</xsl:when>-->
                    </xsl:choose>
                    <xsl:if test="not($returnCount=1)">
                        <xsl:text>s</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:variable name="fhirResource">
                    <xsl:choose>
                        <xsl:when test="$partId='ma'">MedicationRequest</xsl:when>
                        <xsl:when test="$partId='vv'">MedicationRequest</xsl:when>
                        <!--<xsl:when test="$partId='mo'">MedicationOverview</xsl:when>-->
                    </xsl:choose>
                </xsl:variable>
                <nts:include value="assert-returnCount" scope="project">
                    <nts:variable name="description" value="Confirm that the returned searchset Bundle contains {$returnCount} {$partIdEN}."/>
                    <nts:variable name="expression" value="Bundle.entry.where(resource.is({$fhirResource})).count() = {$returnCount}"/>
                </nts:include>
                <!--<action>
                    <assert>
                        <description value="Confirm that the returned searchset Bundle contains {$returnCount} {$partIdEN}."/>
                        <direction value="response"/>
                        <expression value="Bundle.entry.where(resource.is({$fhirResource})).count() = {$returnCount}"/>
                    </assert>
                </action>-->
            </xsl:if>
        </nts:dummy>
    </xsl:template>
    
</xsl:stylesheet>