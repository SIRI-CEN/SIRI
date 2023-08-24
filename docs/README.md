
# Generating OJP Documentation

This document describes the generation of documentation for the OJP XML schemas. There are two goals:

* Generate plain HTML documentation with a table of contents for reference purposes.
* Provide the HTML documentation in a format so it can be easily integrated into the associated CEN standards document which is maintained as an MS Word file.

## Prerequisites

The documentation generation process requires an XSLT 1.0 processor like [Apache Xalan-J](http://xalan.apache.org/xalan-j/index.html) or (xsltproc](http://xmlsoft.org/XSLT/).

On Linux, install xsltproc running `apt-get install xsltproc` (or the required equivalent in non-Debian based distributions).

For Windows, you'll find Windows binaries for xsltproc at http://xmlsoft.org/XSLT/.

## Generation of HTML documentation

### Instructions

On Linux and with the above prerequisites at hand, you can run `generate-tables.sh` to convert the XML schemas into a single HTML file [`index.html`](generated/index.html) in the `generated` subdirectory.

The generated HTML file requires the file `asciidoc.css` to be in the same directory. The above script makes sure it's there.

On Windows, please refer to the `generate-tables.sh` to figure out the necessary program invocations for your XSLT processor of choice.

### Inner workings

`generate-tables.sh` runs `xsltproc` twice. First the file `schema-collection.xml` is run against `ojp-to-prepdoc.xsl`. This combines all references XSD files to a single intermediate XML files which maps all information into a simplified structure that will make it easier in the second step to generate the final HTML documentation.

Once, you have the intermediate XML file (`generated/OJP-prep.xml`), you can run that against the `ojp-prep-to-html-with-toc.xsl` stylesheet. This will generate the final `index.html` (HTML with table of contents). Alternatively, if you don't want the table of contents, you can use the stylesheet `ojp-prep-to-html.xsl`.

## XML Schema Convention Check

There is an additional XSLT stylesheet `check-ojp-schemas.xsl` (invoked by `check-ojp-schemas.sh`) that can be used to check whether certain conventions for the design
of the XML schemas for OJP have been violated.