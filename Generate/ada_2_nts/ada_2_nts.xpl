<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:c="http://www.w3.org/ns/xproc-step" 
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
    xmlns:pxf="http://exproc.org/proposed/steps/file"
    xmlns:f="http://hl7.org/fhir"
    xmlns:nts="http://nictiz.nl/xsl/testscript"
    version="1.0">
    
    <p:input port="source" sequence="true">
        <p:empty/>
    </p:input>
    <p:output port="result" sequence="true">
        <p:empty/>
    </p:output>
    
    <p:option name="project" select="'Medication-9-0-7'"/>
    <p:option name="debug" select="'false'"/>
    
    <!-- All steps in pxf namespace are part of the 'EXProc proposed file utilities extension steps' (http://exproc.org/proposed/steps/fileutils.html) that are supported by the XML Calabash processor. Below, the extension library is imported. The upcoming XProc 3.0 version is expected to incorporate these steps in the standard: https://spec.xproc.org/master/head/file/. -->
    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
    
    <p:variable name="inputDirBase" select="'src/xml'"/>
    <p:variable name="xsltDirBase" select="'src/xslt'"/>
    <p:variable name="outputDirBase" select="'build/artifacts'"/>
    <p:variable name="debugDirBase" select="'build/reports'"/>
    
    <p:documentation>Delete the previous output.</p:documentation>
    <p:documentation>First we create the dir to be sure it exists (otherwise pxf:delete fails).</p:documentation>
    <pxf:mkdir fail-on-error="false">
        <p:with-option name="href" select="string-join(($outputDirBase,$project), '/')"/>
    </pxf:mkdir>
    <p:documentation>Then we delete the directory recursively.</p:documentation>
    <pxf:delete recursive="true" fail-on-error="false">
        <p:with-option name="href" select="string-join(($outputDirBase,$project), '/')"/>
    </pxf:delete>
    
    <pxf:mkdir fail-on-error="false">
        <p:with-option name="href" select="string-join(($debugDirBase,$project), '/')"/>
    </pxf:mkdir>
    <pxf:delete recursive="true" fail-on-error="false">
        <p:with-option name="href" select="string-join(($debugDirBase,$project), '/')"/>
    </pxf:delete>
    
    <!--In Xproc 3, p:directory-list will have an option to list directory contents recursively-->
    <cx:recursive-directory-list name="test">
        <p:with-option name="path" select="string-join(($inputDirBase,$project), '/')"/>
    </cx:recursive-directory-list>
    <!--<p:store indent="true" omit-xml-declaration="false">
        <p:with-option name="href" select="'directory-list.xml'"/>
    </p:store>-->
    
    <p:for-each>
        <p:iteration-source select="//c:directory"/>
        <p:variable name="dirName" select="c:directory/@xml:base"/>
        <p:for-each>
            <p:iteration-source select="c:directory/c:file"/>
            <p:variable name="filename" select="c:file/@name"/>
            <p:variable name="relDir" select="substring-after($dirName,string-join(($inputDirBase,$project),'/'))"/>
            
            <p:load name="load-input">
                <p:with-option name="href" select="concat(string-join(($inputDirBase,$project), '/'),$relDir,$filename)"/>
            </p:load>
            
            <p:load name="load-ada_2_nts-stylesheet">
                <p:with-option name="href" select="concat($xsltDirBase, '/ada_2_nts.xsl')"/>
            </p:load>
            <p:xslt name="ada_2_nts">
                <p:input port="source">
                    <p:pipe port="result" step="load-input"/>
                </p:input>
                <p:input port="stylesheet">
                    <p:pipe port="result" step="load-ada_2_nts-stylesheet"/>
                </p:input>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
            </p:xslt>
            
            <p:try>
                <p:group>
                    <p:documentation>Loads and executes project-specific XSLT if it exists, otherwise throws.</p:documentation>
                    <p:load name="load-project-specific-stylesheet">
                        <p:with-option name="href" select="concat(string-join(($xsltDirBase,$project), '/'),'.xsl')"/>
                    </p:load>
                    <p:xslt name="project-specific">
                        <p:input port="source">
                            <p:pipe port="result" step="load-input"/>
                        </p:input>
                        <p:input port="stylesheet">
                            <p:pipe port="result" step="load-project-specific-stylesheet"/>
                        </p:input>
                        <p:input port="parameters">
                            <p:empty/>
                        </p:input>
                    </p:xslt>
                    
                    <p:insert match="f:TestScript/f:test" position="last-child">
                        <p:input port="source">
                            <p:pipe port="result" step="ada_2_nts"/>
                        </p:input>
                        <p:input port="insertion">
                            <p:pipe port="result" step="project-specific"/>
                        </p:input>
                    </p:insert>
                    <p:unwrap match="f:TestScript/f:test/nts:dummy"/>
                </p:group>
                <p:catch>
                    <p:identity>
                        <p:input port="source">
                            <p:pipe port="result" step="ada_2_nts"/>
                        </p:input>
                    </p:identity>
                </p:catch>
            </p:try>
            
            <p:group>
                <p:variable name="newFilename" select="f:TestScript/f:id/@value"/>
                <p:validate-with-schematron assert-valid="false" name="schematron">
                    <p:input port="schema">
                        <p:document href="../general/schematron/NictizTestScript.sch"/>
                    </p:input>
                    <p:input port="parameters">
                        <p:empty/>
                    </p:input>
                </p:validate-with-schematron>
                <p:store indent="true" omit-xml-declaration="false">
                    <p:with-option name="href" select="concat(string-join(($outputDirBase,$project),'/'),$relDir,$newFilename,'.xml')"/>
                </p:store>
                <p:store indent="true" omit-xml-declaration="false">
                    <p:input port="source">
                        <p:pipe port="report" step="schematron"/>
                    </p:input>
                    <p:with-option name="href" select="concat(string-join(($debugDirBase,$project),'/'),$relDir,$newFilename,'-schematron-report.xml')"/>
                </p:store>
            </p:group>
            
        </p:for-each>
    </p:for-each>
    
    <!--Source: https://xprocbook.com/book/refentry-61.html-->
    <p:declare-step type="cx:recursive-directory-list">
        <p:output port="result"/>
        <p:option name="path" required="true"/>
        <p:option name="include-filter"/>
        <p:option name="exclude-filter"/>
        <p:option name="depth" select="-1"/>
        
        <p:choose>
            <p:when test="p:value-available('include-filter')
                and p:value-available('exclude-filter')">
                <p:directory-list>
                    <p:with-option name="path" select="$path"/>
                    <p:with-option name="include-filter" select="$include-filter"/>
                    <p:with-option name="exclude-filter" select="$exclude-filter"/>
                </p:directory-list>
                </p:when>
            
            <p:when test="p:value-available('include-filter')">
                <p:directory-list>
                    <p:with-option name="path" select="$path"/>
                    <p:with-option name="include-filter" select="$include-filter"/>
                </p:directory-list>
            </p:when>
            
            <p:when test="p:value-available('exclude-filter')">
                <p:directory-list>
                    <p:with-option name="path" select="$path"/>
                    <p:with-option name="exclude-filter" select="$exclude-filter"/>
                </p:directory-list>
            </p:when>
            
            <p:otherwise>
                <p:directory-list>
                    <p:with-option name="path" select="$path"/>
                </p:directory-list>
                </p:otherwise>
        </p:choose>
        
        <p:viewport match="/c:directory/c:directory">
            <p:variable name="name" select="/*/@name"/>
            
            <p:choose>
                <p:when test="$depth != 0">
                    <p:choose>
                        <p:when test="p:value-available('include-filter') and p:value-available('exclude-filter')">
                            <cx:recursive-directory-list>
                                <p:with-option name="path" select="concat($path,'/',$name)"/>
                                <p:with-option name="include-filter" select="$include-filter"/>
                                <p:with-option name="exclude-filter" select="$exclude-filter"/>
                                <p:with-option name="depth" select="$depth - 1"/>
                            </cx:recursive-directory-list>
                        </p:when>
                        
                        <p:when test="p:value-available('include-filter')">
                            <cx:recursive-directory-list>
                                <p:with-option name="path" select="concat($path,'/',$name)"/>
                                <p:with-option name="include-filter" select="$include-filter"/>
                                <p:with-option name="depth" select="$depth - 1"/>
                            </cx:recursive-directory-list>
                        </p:when>
                        
                        <p:when test="p:value-available('exclude-filter')">
                            <cx:recursive-directory-list>
                                <p:with-option name="path" select="concat($path,'/',$name)"/>
                                <p:with-option name="exclude-filter" select="$exclude-filter"/>
                                <p:with-option name="depth" select="$depth - 1"/>
                            </cx:recursive-directory-list>
                        </p:when>
                        
                        <p:otherwise>
                            <cx:recursive-directory-list>
                                <p:with-option name="path" select="concat($path,'/',$name)"/>
                                <p:with-option name="depth" select="$depth - 1"/>
                            </cx:recursive-directory-list>
                        </p:otherwise>
                    </p:choose>
                </p:when>
                <p:otherwise>
                    <p:identity/>
                </p:otherwise>
            </p:choose>
        </p:viewport>
    </p:declare-step>
</p:declare-step>