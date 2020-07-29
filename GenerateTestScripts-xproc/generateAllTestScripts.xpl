<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:c="http://www.w3.org/ns/xproc-step" 
    xmlns:f="http://hl7.org/fhir"
    xmlns:nts="http://nictiz.nl/xsl/testscript"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">
    
    <p:input port="source" sequence="true">
        <p:empty/>
    </p:input>
    <p:output port="result" sequence="true">
        <p:empty/>
    </p:output>
    
    <p:option name="project" required="true"/>
    <p:option name="generateXisWithSetup" select="'false'"/>
    
    <p:variable name="inputDirBase" select="'src/xml'"/>
    <p:variable name="xsltDirBase" select="'src/xslt'"/>
    <p:variable name="outputDirBase" select="'build/artifacts'"/>
    <p:variable name="debugDirBase" select="'build/reports'"/>
    
    <p:variable name="xisDir" select="'XIS-Server'"/>
    <p:variable name="xisWithSetupDir" select="'XIS-Server-nictiz-intern'"/>
    
    <p:documentation>Delete the previous output. Dangerous if the output directory serves as input for another process (e.g. the -Dev directory).</p:documentation>
    <p:file-delete href="{string-join(($outputDirBase,$project), '/')}" recursive="true" fail-on-error="false"/>
    <p:file-delete href="{string-join(($debugDirBase,$project), '/')}" recursive="true" fail-on-error="false"/>
    
    <p:documentation>Recursively list input directory content.</p:documentation>
    <p:directory-list path="{string-join(($inputDirBase,$project), '/')}" max-depth="unbounded"/>
    <p:for-each>
        <p:with-input select="//c:directory"/>
        <!--<p:variable name="absoluteDir" select="base-uri(c:directory/@xml:base)"/>-->
        <!--Doubles current directory name. Bug in processor? https://sourceforge.net/p/morganaxproc-iiise/tickets/29/ Fix:-->
        <p:variable name="absoluteDirDoubled" select="base-uri(c:directory/@xml:base)"/>
        <p:variable name="tokens" select="tokenize($absoluteDirDoubled,concat('/',c:directory/@name))"/>
        <p:variable name="absoluteDir" select="string-join($tokens[not(.=$tokens[last()])],concat('/',c:directory/@name))"/>
        
        <p:documentation>Exclude directories that start with '_' (for example _resources, _components).</p:documentation>
        <p:variable name="dirName" select="c:directory/@name"/>
        <p:if test="not(starts-with($dirName,'_'))">
            <p:for-each>
                <p:with-input select="c:directory/c:file"/>
                <p:variable name="filename" select="c:file/@name"/>
                <p:variable name="relDir" select="substring-after($absoluteDir,concat($project,'/'))"/>
                <p:variable name="absoluteInputDir" select="substring-before($absoluteDir,$relDir)"/>
                
                <p:documentation>Access XML to determine scenario.</p:documentation>
                <p:load href="{base-uri(c:file/@xml:base)}" name="load-input"/>
                <p:variable name="nts-scenario" select="f:TestScript/@nts:scenario"/>
                
                <p:documentation>Apply XSLT to each input XML-file.</p:documentation>
                <p:choose>
                    <p:when test="$nts-scenario='server'">
                        <p:documentation>For each expectedResponseFormat</p:documentation>
                        <p:variable name="expectedResponseFormats" select="('xml','json')"/>
                        <p:for-each>
                            <p:with-input select="$expectedResponseFormats"/>
                            <p:variable name="newFilename" select="concat(substring-before($filename,'.xml'),'-',.,'.xml')"/>
                            <p:xslt name="testscript-xslt">
                                <p:with-input port="source" pipe="result@load-input"/>
                                <p:with-input port="stylesheet">
                                    <p:document href="{concat($xsltDirBase,'/generateTestScript.xsl')}"/>
                                </p:with-input>
                                <p:with-option name="parameters" select="map{
                                    'inputDir' : $absoluteInputDir,
                                    'referenceFolder' : '../_reference',
                                    'expectedResponseFormat' : .,
                                    'projectComponentFolder' : 'XIS-Server/_components',
                                    'commonComponentFolder' : '../../../general/common-tests'
                                    }"/>
                            </p:xslt>
                            
                            <p:documentation>Remove setup element if necessary.</p:documentation>
                            <p:if test="not($generateXisWithSetup='true')">
                                <p:delete match="f:TestScript/f:setup" name="delete-setup"/>
                            </p:if>
                            
                            <p:documentation>Store result.</p:documentation>
                            <p:store href="{string-join(($outputDirBase,$project,$relDir,$newFilename),'/')}" serialization="map{'indent':'true','omit-xml-declaration':'false'}"/>
                            
                            <p:documentation>Separately store XIS with setup phase.</p:documentation>
                            <p:if test="$generateXisWithSetup='true'">
                                <p:variable name="newRelDir" select="replace($relDir,$xisDir,$xisWithSetupDir)"/>
                                <p:store href="{string-join(($outputDirBase,$project,$newRelDir,$newFilename),'/')}" serialization="map{'indent':'true','omit-xml-declaration':'false'}">
                                    <p:with-input port="source" pipe="result@testscript-xslt"/>
                                </p:store>
                            </p:if>
                        </p:for-each>
                    </p:when>
                    <p:otherwise>
                        <p:xslt name="testscript-xslt" message="{$filename}">
                            <p:with-input port="source" pipe="result@load-input"/>
                            <p:with-input port="stylesheet">
                                <p:document href="{concat($xsltDirBase,'/generateTestScript.xsl')}"/>
                            </p:with-input>
                            <p:with-option name="parameters" select="map{
                                'inputDir' : $absoluteInputDir,
                                'referenceFolder' : '../_reference',
                                'projectComponentFolder' : 'PHR-Client/_components',
                                'commonComponentFolder' : '../../../general/common-tests'
                                }"/>
                        </p:xslt>
                        <p:store href="{string-join(($outputDirBase,$project,$relDir,$filename),'/')}" serialization="map{'indent':'true','omit-xml-declaration':'false'}"/>
                    </p:otherwise>
                </p:choose>
            </p:for-each>
        </p:if>
    </p:for-each>
    
</p:declare-step>