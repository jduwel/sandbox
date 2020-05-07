# ada_2_nts

Project to be able to generate NTS (Nictiz TestScript) files from ADA input. 

Use XML Calabash to run `ada_2_nts.xpl` with 1 parameter: $project or start an Xproc Transformation Scenario from `ada_2_nts.xpl` in Oxygen: https://www.oxygenxml.com/doc/versions/22.0/ug-editor/topics/xproc-transformation-scenario.html

ADA input files are placed in `src/xml/{$project}`. `src/xml` is added to `.gitignore` to prevent manual edits to ADA files. 

Project-specific additions to the NTS files can be added by adding `{$project}.xsl` to `src/xslt`. These will be added to the test-element in the TestScript. Make sure all additions are wrapped in an nts:dummy element.

Output is placed in `build/artifacts/{$projects}` (also in `.gitignore`). If correct, the results should be copied manually to the correct folder in `Generate` in the root of this repository and committed.