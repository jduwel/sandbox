# generateAllTestScripts Xproc 3.0

## Requirements
* [MorganaXProc-III](https://www.xml-project.com/morganaxproc-iii/) - Tested with v0.9.2.5-beta
* [Saxon 9.9](https://sourceforge.net/projects/saxon/files/Saxon-HE/9.9/) - Tested with v9.9.1.7

MorganaXproc-III is the only available Xproc 3.0 processor at the moment, which only works with Saxon version 9.9 and up. Place the Saxon JAR in the MorganaXproc-III lib folder.

Call the Xproc pipeline from the MorganaXproc-III folder with:
`Morgana.bat [path to repository]\Generate\generateAllTestScripts.xpl -option:project=Medication-9-0-7`

By default, the pipeline looks for XML files in the folder `src/xml/[project name]` , for example `src/xml/Medication-9-0-7`. Nested directories are supported.

Output is placed in `build/artifacts/[project name]`.

To generate TestScripts for XIS servers with setup phase for internal use, add the `-option:generateXisWithSetup=true` flag.

When editing XPL files with Oxygen, please note that Xproc 1.0 validation is hardcoded (you will get validation errors in Oxygen). This should be [solved in version 22.1](https://www.oxygenxml.com/forum/topic21228.html).
