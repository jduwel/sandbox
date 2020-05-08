<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:c="http://www.w3.org/ns/xproc-step" 
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
    <pxf:delete fail-on-error="false">
        <p:with-option name="href" select="string-join(($outputDirBase,$project), '/')"/>
    </pxf:delete>
    
    <!-- TO DO: make recursive (XIS or PHR subdirs) -->
    <p:directory-list>
        <p:with-option name="path" select="string-join(($inputDirBase,$project), '/')"/>
    </p:directory-list>
    <p:for-each>
        <p:iteration-source select="c:directory/c:file"/>
        <p:variable name="filename" select="c:file/@name"/>

        <p:load name="load-input">
            <p:with-option name="href" select="string-join(($inputDirBase,$project,$filename), '/')"/>
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
        
        <p:store indent="true" omit-xml-declaration="false">
            <p:with-option name="href" select="concat(string-join(($outputDirBase,$project,f:TestScript/f:id/@value), '/'),'.xml')"/>
        </p:store>
    </p:for-each>
    
</p:declare-step>