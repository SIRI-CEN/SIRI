(:
 : xco-html - functions creating HTML reports
 :)
module namespace hl="http://www.parsqube.de/ns/xco/html";
import module namespace co="http://www.parsqube.de/ns/xco/constants"
    at "xco-constants.xqm";
import module namespace cu="http://www.parsqube.de/ns/xco/custom"
    at "xco-custom.xqm";
import module namespace dg="http://www.parsqube.de/ns/xco/debug"
    at "xco-debug.xqm";
import module namespace dm="http://www.parsqube.de/ns/xco/domain"
    at "xco-domain.xqm";
import module namespace eu="http://www.parsqube.de/ns/xco/edesc-util"
    at "xco-edesc-util.xqm";
import module namespace fu="http://www.parsqube.de/ns/xco/file-util"
    at "xco-file-util.xqm";
import module namespace hu="http://www.parsqube.de/ns/xco/html-util"
    at "xco-html-util.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
    at "xco-namespace.xqm";
import module namespace u="http://www.parsqube.de/ns/xco/util"
    at "xco-util.xqm";
declare namespace z="http://www.parsqube.de/ns/xco/structure";
declare boundary-space preserve;

(:~
 : Transforms an XML report into an HTML report.
 :
 : If the report consists of several documents, they are written into files.
 : In this case, this function returns only one of the report documents.
 :
 : @param xmlReport an XML report
 : @param options options controlling the processing
 : @return the HTML report, or part of the report
 :)
declare function hl:htmlReport($reportType as xs:string,
                               $xmlReport as element()?,
                               $xmlReportDir as xs:string?,
                               $options as map(xs:string, item()*)?)
        as element()* {
    switch($reportType)
    case 'contab' return hl:contabReport($xmlReport, $xmlReportDir, $options)
    default return error(QName((), 'INVALID_ARG'), 
        'Unknown report type: '||$reportType)
};

(:~
 : Transforms an edesc report into an contab report. 
 :
 : @param report XML report, report type = "edesc"
 : @param options options controlling the processing
 : @return the HTML report "contab"
 :)
declare function hl:contabReport($report as element()?,
                                 $reportDir as xs:string?,
                                 $options as map(xs:string, item()*)?)
        as element()* {
    let $domains := $options?domains
    let $withEnumDict as xs:boolean := $options?withEnumDict
    return
        (: No domains defined - create a single report 
           (Note: reportDir only supported in case of domains) :)
        if (not($domains)) then ( 
            hl:contabReport_domain($report, (), $options),
            hl:enumDict_domain($report, (), $options)[$withEnumDict]
        )
            
        (: Domains have been defined :)
        else
            let $domainReports := (
                for $domain in $domains/domain
                let $_DEBUG := trace($domain/@name, '*** Create report for domain: ')
                let $domainReport := 
                    if ($report) then $report/z:domain[@z:id eq $domain/@id]
                    else 
                        let $inputPath := dm:getInputReportPath('edesc', $reportDir, $domain, $options)
                        return doc($inputPath)/*
                return ( 
                    $domainReport/hl:contabReport_domain(., $domain, $options),
                    $domainReport/hl:enumDict_domain(., $domain, $options)[$withEnumDict]
                ),
                hl:contabReportIndex($domains/domain, $options)
            )
            return $domainReports[1]                     
};

(:~
 : Transforms an edesc report or report domain into a contab report. 
 :
 : If no domains have been defined, the function creates the complete
 : report, otherwise the part corresponding to a single domain.
 :
 : @param report an edesc report, complete or limited to a domain
 : @param domain an element describing the domain
 : @param options options controlling the processing
 : @return edesc html report, or a part of the report dealing with a domain
 :)
declare function hl:contabReport_domain(
                                $report as element(),
                                $domain as element(domain)?,
                                $options as map(xs:string, item()*)?)
        as element() {
    let $reportFilePath := dm:getReportPath('edesc-htrml', $domain, $options)        
    let $head := hl:contabReport_head($reportFilePath, $domain, $options)
    let $toc := hl:contabReport_toc($report, $domain, $options)
    let $xsdDivs :=
        for $schema at $schemaNr in $report/z:schema
        let $schemaFileName := $schema/base-uri(.) ! replace(., '.+/', '')
        let $schemaName := $schemaFileName ! replace(., '(.*)\.[^.]+$', '$1')
        let $anno := $schema/z:annotation/z:documentation/string()
        let $headline := ($anno, $schemaFileName)[1]
        let $stypes := $schema/eu:getEdescReportSimpleTypes(.)
        let $stypesTable := eu:stypesTable($stypes, $domain, $options)[$stypes]        
        let $tables :=
            for $comp at $cnr in (
                $schema/z:components/*,
                $schema/z:components/*//z:complexType[@z:typeID] ! u:copyNode(.)
            )
            let $compNr := 
                let $shift := if ($stypes) then 1 else 0
                return $cnr + $shift
            return
                typeswitch($comp)
                case element(z:complexType) | 
                     element(z:group) |
                     element(z:element) return
                    hl:contabReport_complexComp($comp, $compNr, $schemaNr, $domain, $options)
                case element(z:simpleType) return ()
                case element(z:attributeGroup) return ()
                case element(z:attribute) return ()                
                default return error('Unexpected component, elem name: '||name($comp))
        return
            <div class="sect1" id="schema_{$schemaName}">{
                <h2>{$schemaNr}. {$headline}</h2>,
                
                if (not($stypes)) then () else 
                    hl:contabReport_stypes($schemaName, $schemaNr, $stypesTable),
                $tables
            }</div>
            
    let $title := ($domain/processing/title/<h1>{node()}</h1>, <h1>API Content</h1>)[1]
    let $htmlReport :=
        <html lang="en" xml:lang="en">{        
            $head,
            <body>{
                <div id="header">{
                    $title,
                    $toc                      
                }</div>,
                <div id="content">{
                    $xsdDivs
                }</div>
           }</body>
       }</html>
       ! u:prettyNode(.)
    let $_WRITE :=
        let $reportPath := dm:getReportPath('contab', $domain, $options)
        where ($reportPath)
        return u:writeXmlDoc($reportPath, $htmlReport)
    return $htmlReport       
};

(:~
 : Returns a <div> element containing a TOC.
 :)
declare function hl:contabReport_toc(
                              $report as element(),
                              $domain as element(domain)?,                              
                              $options as map(xs:string, item()*)?)
        as element() {
    let $custom := $options?custom
    let $xsdDict := $options?schemas return
    
    <div class="toc" id="toc">
        <div id="toctitle">Table of Contents</div>
        <ul class="sectlevel1">{
            for $schema at $snr in $report/z:schema
            let $baseUri := $schema/base-uri(.)
            let $xsd := $options?schemas($baseUri)
            let $schemaFileName := $baseUri ! file:name(.)
            let $schemaName := $schemaFileName ! replace(., '(.*)\.[^.]+$', '$1')
            let $xsdTitle := cu:xsdTitle($schema/@filePath ! $xsdDict(.), 
                'contab', $domain/@id, $options?custom) 
            let $stypes := $schema/z:components/z:simpleType
            let $shift := if ($stypes) then 1 else 0
            return
                <li>
                    <a shape="rect" href="#schema_{$schemaName}">{$snr}. {$xsdTitle}</a>
                    <ul class="sectlevel2">{
                        <li>
                            <a shape="rect" 
                               href="#schema_{$schemaName}_std">{$snr}.1. Simple type definitions</a>
                        </li>[$stypes],
                    
                        for $comp at $cnr in $schema/z:components/*
                            [self::z:element, self::z:complexType, self::z:group]
                        let $compNr := $shift + $cnr
                        let $compKind := $comp/local-name(.)
                        let $name := $comp/@z:name/string()
                        let $dispName := cu:customComponentName(
                            $name, $compKind, 'main', 'contab', $domain/@id, $custom)
                        let $ttp := (
                            typeswitch($comp)
                            case element(z:element) return 'The toplevel element~~element.'
                            case element(z:complexType) return 'The complexType~~type.'
                            case element(z:group) return 'The ~group~group.'
                            default return error()
                        ) => tokenize('~')
                        let $txt1 := $ttp[1]
                        let $txt2 := $ttp[2]
                        let $idPrefix := $ttp[3]
                        return
                        <li>
                            <a shape="rect" 
                               href="#{$idPrefix}{$name}">{$snr}.{$compNr} {$txt1} <code>{$dispName}</code>{$txt2}
                            </a>
                        </li>
                    }</ul>
               </li>
        }</ul>
    </div>
};

(:~
 : Returns the head part of a contab report page.
 :
 : @param report XML report
 : @param reportPath the file path where this document will be written
 : @param domain the current domain
 : @param options options controlling the processing
 : @return component descriptors
 :)
declare function hl:contabReport_head(
                                    $reportPath as xs:string,
                                    $domain as element(domain)?,
                                    $options as map(xs:string, item()*)?)
        as element() {
  let $title := ($domain/processing/title/string(), 'API types')[1]
  let $odir := $options?odir
  let $cssFilePath := $odir||'/asciidoc.css'
  let $cssRelFilePath := fu:getRelPath($reportPath ! fu:getParentPath(.), $cssFilePath) 
  return
  
  <head>
    <title>{$title}</title>
    <meta charset="UTF-8"/>
    <meta http-equiv="content-type" content="text/html;charset=UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <script type="text/javascript"><![CDATA[
      document.addEventListener('DOMContentLoaded', function() {
        var headers = ['h2', 'h3', 'h4', 'h5', 'h6'];
        for (var i = 0; i &lt; headers.length; i++) {
          var headerElements = document.getElementsByTagName(headers[i]);
          for (var j = 0; j &lt; headerElements.length; j++) {
            var header = headerElements[j];
            header.innerHTML += '&lt;a class="header-link" href="#' + header.parentNode.id + '"&gt;&lt;span class="link-icon"&gt;&lt;/span&gt;&lt;/a&gt;';
          }
        }
      });
    ]]></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Open+Sans:300,300italic,400,400italic,600,600italic%7CNoto+Serif:400,400italic,700,700italic%7CDroid+Sans+Mono:400,700"/>,
    <link rel="stylesheet" href="{$cssRelFilePath}"/>
    <style><![CDATA[
      .header-link {
        position: relative;
        font-size: 0.65em;
        left: 0.5em;
        opacity: 0;

        -webkit-transition: opacity 0.2s ease-in-out 0.1s;
        -moz-transition: opacity 0.2s ease-in-out 0.1s;
        -ms-transition: opacity 0.2s ease-in-out 0.1s;
      }
      h2:hover .header-link,
      h3:hover .header-link,
      h4:hover .header-link,
      h5:hover .header-link,
      h6:hover .header-link {
        opacity: 1;
      }

      .link-icon {
        width: 22px;
        height: 18px;
        display: inline-block;
        background: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 512'%3e%3c!--! Font Awesome Pro 6.2.0 by %40fontawesome - https://fontawesome.com License - https://fontawesome.com/license (Commercial License) Copyright 2022 Fonticons%2c Inc.--%3e%3cpath d='M579.8 267.7c56.5-56.5 56.5-148 0-204.5-50-50-128.8-56.5-186.3-15.4l-1.6 1.1c-14.4 10.3-17.7 30.3-7.4 44.6s30.3 17.7 44.6 7.4l1.6-1.1c32.1-22.9 76-19.3 103.8 8.6 31.5 31.5 31.5 82.5 0 114L422.3 334.8c-31.5 31.5-82.5 31.5-114 0-27.9-27.9-31.5-71.8-8.6-103.8l1.1-1.6c10.3-14.4 6.9-34.4-7.4-44.6s-34.4-6.9-44.6 7.4l-1.1 1.6C206.5 251.2 213 330 263 380c56.5 56.5 148 56.5 204.5 0l112.3-112.3zM60.2 244.3c-56.5 56.5-56.5 148 0 204.5 50 50 128.8 56.5 186.3 15.4l1.6-1.1c14.4-10.3 17.7-30.3 7.4-44.6s-30.3-17.7-44.6-7.4l-1.6 1.1c-32.1 22.9-76 19.3-103.8-8.6C74 372 74 321 105.5 289.5l112.2-112.3c31.5-31.5 82.5-31.5 114 0 27.9 27.9 31.5 71.8 8.6 103.9l-1.1 1.6c-10.3 14.4-6.9 34.4 7.4 44.6s34.4 6.9 44.6-7.4l1.1-1.6C433.5 260.8 427 182 377 132c-56.5-56.5-148-56.5-204.5 0L60.2 244.3z'/%3e%3c/svg%3e") no-repeat;
      }
    ]]></style>
  </head>
};

declare function hl:contabReport_stypes($schemaName, 
                                        $schemaNr,
                                        $stypesTable)
        as element(div) {
    <div class="simple-type-definitions" id="schema_{$schemaName}_std">{
        <h3>{$schemaNr}.1. Simple type definitions</h3>,
        <div class="sectionbody">{
            <table class="tableblock frame-all grid-all spread">{
                <colgroup span="1">
                    <col span="1" style="width:28%"/>
                    <col span="1" style="width:28%"/>
                    <col span="1" style="width:44%"/>
                </colgroup>,
                <tbody>{
                    for $row in $stypesTable/*
                    let $nameHtml :=
                        let $raw := $row/name
                        return
                            if ($raw/contains(., '#')) then 
                                hu:getLocalTypeLabelLines($raw)
                            else 
                                <strong><code>{$raw/node()}</code></strong>
                    let $enums := $row/description/enum
                    let $anno := ($row/anno[string()]/string(), '-')[1]
                    return if (not($enums)) then
                    
                    (: Case 1 - not an enum gtype :)                        
                    $row/
                    <tr>{
                        name/
                        <td colspan="1" rowspan="1">{
                            hu:classTd(),
                            <p id="{$row/@divId}">{
                                hu:classP(), $nameHtml
                            }</p>
                        }</td>,
                        description/
                        <td colspan="1" rowspan="1">{
                            hu:classTd(),
                            <p>{hu:classP(), node()}</p>
                         }</td>,
                         anno/
                         <td colspan="1" rowspan="1">{
                             hu:classTd(),
                             <p>{hu:classP('anno-text'), $anno}</p>
                         }</td>
                    }</tr>                                

                    (: Case 2 - enum gtype :)
                    else (
                    $row/
                    <tr>{                    
                        name/
                        <td colspan="1" rowspan="2">{
                            hu:classTd(),
                            <p id="{$row/@divId}">{
                                hu:classP(),
                                if (not(@linkName/string())) then 
                                    $nameHtml
                                else
                                    <a shape="rect" href="{@linkName}">{$nameHtml}</a>
                            }</p>
                        }</td>,
                         anno/
                         <td colspan="2" rowspan="1">{
                             hu:classTd(),
                             <p>{hu:classP('anno-text'), $anno}</p>
                         }</td>
                    }</tr>,
                    
                    <tr>{
                        <td colspan="2">{
                            <table>{
                                hu:classTable(),
                                <colgroup span="1">
                                    <col span="1" style="width:28%"/>
                                    <col span="1" style="width:72%"/>
                                </colgroup>,
                                
                                <tbody>{
                                    $enums/
                                    <tr>{
                                        <td>{
                                            hu:classTd(),
                                            <p>{hu:classP(), @value/string(.)}</p>
                                        }</td>,
                                        <td>{
                                            hu:classTd(),
                                            <p>{hu:classP('anno-text'), 
                                                (@anno/string()[string()], '-')[1]
                                            }</p>
                                        }</td>
                                     }</tr>
                                 }</tbody>
                             }</table>
                         }</td>
                     }</tr>)
                    
                }</tbody>
            }</table>
           
        }</div>
    }</div>        
};

(:~
 : Contributes to an contab report the description of a complex
 : component. A complex component can be an element declaration,
 : a type definition or a group definitions.
 :
 : @param comp extended descriptor of a schema component
 : @param compNr an ordinal number defining the position of the
 :   component within a sequence of components
 : @param schemaNr an ordinal number defining the position of the
 :   containing schema withion a sequence of schemas
 : @param domain an optional definition of the containing domain
 : @return an HTML div element
 :) 
declare function hl:contabReport_complexComp(
                                 $comp as element(),
                                 $compNr as xs:integer,
                                 $schemaNr as xs:integer,
                                 $domain as element(domain)?,
                                 $options as map(xs:string, item()*)?)
        as element()* {
    let $custom := $options?custom        
    let $contentTable := eu:contentTable($comp, $domain, $options)    
    let $compKind := $comp/local-name(.)
    let $kindName := 
        switch($compKind)
        case 'complexType' return 'complex type' 
        case 'group' return 'group'
        case 'element' return 'toplevel element'
        default return error()
    let $idPrefix := 
        switch($compKind)
        case 'complexType' return 'type' 
        default return $comp/local-name(.)
    let $name := $contentTable/@name
    let $kind := $contentTable/@kind
    let $typeId := $contentTable/@typeID
    let $typeLabel := $contentTable/@typeLabel
    let $compDisplayName := 
        if ($typeLabel) then $typeLabel/string()
        else
            cu:customComponentName(
                $name, $compKind, 'main', 'contab', $domain/@id, $custom)    
    let $lexName := $contentTable/@name
    let $divId :=
        if (not($comp/self::z:complexType/@z:typeID)) then $idPrefix||'.'||$lexName
        else 'local-type.'||$comp/@z:typeID
    return (    
        <div class="sect2" id="{$divId}">{
            <h3>{$schemaNr}.{$compNr}. The {$kindName} <code>{$compDisplayName}</code></h3>,
            <div class="sectionbody">{
                if ($contentTable/@variant eq 'typeName') then 
                    hl:contentHtmlTable_variant_typeName($contentTable)
                else
                     hl:contentHtmlTable_std($contentTable, $comp, $domain, $options)
            }</div>
        }</div>
    )    
};

(:~
 : Returns a table element representing the content of a complex component.
 :
 : @param contentTable a content table containing the essential data
 : @param comp a component descriptor
 : @param domain the domain containing the component
 : @param options options controlling the processing
 : @return a table element
 :)
declare function hl:contentHtmlTable_std($contentTable as element(),
                                         $comp as element(),
                                         $domain as element(domain)?,
                                         $options as map(xs:string, item()*))
        as element(table) {
    let $custom := $options?custom        
    let $compKind := $contentTable/@kind/string()
    let $compAnno := $contentTable/(anno[string()]/string(), '-')[1]  
    let $name := $contentTable/@name
    let $baseName := $contentTable/@baseName
    let $baseLinkName := $contentTable/@baseLinkName
    let $compositor := 
        $comp/*/descendant::*[self::z:sequence, self::z:choice, self::z:choice][1]
        /local-name(.)
        ! replace(., '.*:', '')
    let $typeId := $contentTable/@typeID
    let $typeLabel := $contentTable/@typeLabel
    let $compDisplayName := 
        if ($typeLabel) then $typeLabel/hu:getLocalTypeLabelLines(.) (: u:getDescriptorLocalTypeLabelDivs(.) :)
        else
            cu:customComponentName(
                $name, $compKind, 'main', 'contab', $domain/@id, $custom)
            ! <code>{.}</code>
    let $baseDisplayName := 
        $baseName ! cu:customComponentName(
            ., $compKind, 'sub', 'contab', $domain/@id, $custom)    
            
    let $baseTypeContent := $contentTable/rows/baseTypeContent
    let $typeContent := $contentTable/rows/typeContent
    let $withBaseType := exists($baseTypeContent)  
    let $baseTypeHasItems := exists($baseTypeContent//row/name)
    let $firstRowOwnContent := $typeContent/descendant::row[1][$withBaseType]
    let $typeIsRestriction := $typeContent/@isRestriction eq 'yes'
    return
    
    <table>{
        hu:classTable(),
        hu:standardColGroup6(),
        <tbody>{     
            (: Headline providing component name, base type name or link, component annotation 
               =============================================================================== :)
            <tr>{
                (: Component display name :)
                hu:tdWithContent($compDisplayName, 4, 1)
                ,
                (: Base type name or link :)
                let $content :=
                    if (not($baseName)) then ()
                    else if (not($baseLinkName)) then <code>{$baseDisplayName}</code>
                    else
                        <a shape="rect" href="{$baseLinkName}" 
                           title="{$baseDisplayName}">{$baseDisplayName}</a>
                return hu:tdWithContent($content, 1, 1),
                
                (: Component annotation :) 
                hu:tdWithContent($compAnno, 1, 1, 'anno-text')
            }</tr>,
            hu:tableTextLine(
                ('The element content starts with ', <b>items inherited</b>, ' from the base type:'),
                 'announceBase', ())[$withBaseType][$baseTypeHasItems]
            ,
            (:
            hu:tableTextLine(
                ('The element contains a ', <em>{$compositor}</em>, ' of the following elements:'))
            ,
            :)
            for $row in $contentTable//row
            let $typeCategory := $row/@typeCategory
            let $isComplex := $typeCategory eq 'cc'
            let $displayName := $row/name/(
                if (not($custom)) then . else 
                    cu:customComponentName(
                        ., 'element', 'sub', 'contab', $domain/@id, $custom))            
            let $isMandatory := not($row/occ/starts-with(., '0'))
            let $fnItemName := function($name, $linkName, $isMandatory) {
                let $name :=
                    if ($linkName) then (
                        text{'→‍'}, 
                        <a shape="rect" href="{$linkName}" title="{$displayName}">{
                           $displayName}</a>)
                    else text{$displayName}
                return
                    if ($isMandatory) then <code><strong>{$name}</strong></code>
                    else <code>{$name}</code>
                    (:
                if ($isMandatory) 
                then <code><strong>{$name}</strong></code> 
                else <code>{$name}</code>
                :)
            }
            let $occValue := '-'[$row/branch/string()]||$row/occ
            let $occTitle :=
                let $min := $row/occ/substring-before(., ':')
                let $max := $row/occ/substring-after(., ':')
                let $piece1 := if ($min eq '0') then 'optional' else 'mandatory'
                let $piece2 := 
                    if ($max eq '1')  then 'single' 
                    else if ($max ne '*') then 'at most '||$max
                    else if ($piece1 eq 'optional') then 'multiple'
                    else 'at least one'
                let $piece3 := if ($row/branch/string()) then 'part of a choice' else ()
                return string-join(($piece1, $piece2, $piece3), ', ')
(:            
mandatory, at least one
mandatory, single
optional, multiple
optional, single
mandatory, at least one, part of a choice
mandatory, single, part of a choice
optional, single, part of a choice
:)
            let $typeCatMarker := 
                switch($typeCategory)
                case 'cc' return '+'
                case 'cs' return '>'
                default return ()
            let $startOwnContent := $row is $firstRowOwnContent
            let $startOwnContentMsg :=
                if (not($startOwnContent)) then ()
                else if ($typeIsRestriction) then (
                    'Base type content is ', <i>restricted</i>, ', resulting in the following ', <b>own content</b>, ':')
                else (
                    'Inherited content is followed by ', <b>own content</b>, ':')
                
            let $startChoiceItems := $row/@startChoice/tokenize(., ';\s*')
            return (
                hu:tableTextLine($startOwnContentMsg, 'announceBase', ())[$startOwnContent]
                ,                
                if (empty($startChoiceItems)) then () else
                for $startChoiceItem in $startChoiceItems
                let $items := tokenize($startChoiceItem, ',\s*')
                let $contextbranch := $items[starts-with(., 'contextbranch')] ! substring-after(., '=')
                let $elems := $items[starts-with(., 'elems')] ! substring-after(., '=')
                let $seqs := $items[starts-with(., 'seqs')] ! substring-after(., '=')
                let $startText :=
                    if (not($contextbranch)) then 'The '
                    else
                        'In case of choice '''||$contextbranch||''', the '
                let $alternatives := string-join((
                    $elems ! ('elements ('||$elems||')'),
                    $seqs ! ('element sequences ('||$seqs||')')
                    ), ' or ')
                return
                    hu:tableTextLine(
                    ($startText, 'element contains ', <em>one</em>, 
                     ' of the following '||$alternatives))
                ,
                <tr>{
                    $row/group/
                    <td colspan="{@colspan}" rowspan="{@rowspan}">{ 
                        hu:classTd(),
                        let $displayName :=
                            if (not($custom)) then . else 
                                cu:customComponentName(
                                ., 'group', 'sub', 'contab', $domain/@id, $custom)
                        return
                            <a shape="rect" href="{@linkName}" title="{$displayName}">{$displayName}</a>
                    }</td>,
                    $row/branch/
                    <td colspan="{@colspan}" rowspan="{@rowspan}">{
                        hu:classTd(),                        
                        <p>{
                            hu:classP(),
                            <em>{string()}</em>
                        }</p>
                    }</td>,
                    $row/name/
                    <td colspan="{@colspan}" rowspan="{@rowspan}">{
                        hu:classTd(),
                        <p>{
                            hu:classP(), 
                            $fnItemName($displayName, @linkName, $isMandatory)
                            (:
                            if (@linkName) then $fnItemName((
                                text{'→‍'}, <a shape="rect" href="{@linkName}" 
                                    title="{$displayName}">{$displayName}</a>),
                                $isMandatory)
                            else
                                $fnItemName($displayName, $isMandatory)
                            :)
                        }</p>
                    }</td>,
                    $row/occ/
                    <td colspan="{@colspan}" rowspan="{@rowspan}">{
                        hu:classTd(),
                        <p>{
                            hu:classP(),
                            if ($isMandatory) then
                                <code><strong title="{$occTitle}">{$occValue}</strong></code>
                            else
                                <span title="{$occTitle}">{$occValue}</span>
                        }</p>
                    }</td>,
                    $row/type/
                    <td colspan="{@colspan}" rowspan="{@rowspan}">{
                        hu:classTd(),
                        let $displayName :=
                            if (not($custom)) then . else 
                            cu:customComponentName(
                                ., 'complexType', 'sub', 'contab', $domain/@id, $custom)
                        return
                            <p>{
                                hu:classP(),
                                <em>{
                                    if (@builtin[string()]/xs:boolean(.)) then text {string()}
                                    else (
                                        $typeCatMarker,
                                        <a shape="rect" href="{@linkName}" title="{$displayName}">{$displayName}</a>
                                    )
                                }</em>
                            }</p>
                    }</td>,
                    $row/anno/
                    <td colspan="{@colspan}" rowspan="{@rowspan}">{
                        hu:classTd(),
                        <p>{hu:classP('darkbrown'), string()}</p>
                    }</td>
                }</tr>
            )
        }</tbody>
    }</table>
};

(:~
 : Returns a table element representing the content of an
 : element component with a type attribute.
 :
 : @param contentTable a content table containing the essential data
 : @param comp a component descriptor
 : @param domain the domain containing the component
 : @param options options controlling the processing
 : @return a table element
 :)
declare function hl:contentHtmlTable_variant_typeName($contentTable as element())
        as element(table) {
    <table>{
        hu:classTable(),    
        hu:standardColGroup6(),
        <tbody>{
            $contentTable/descendant::row[1]/
            <tr>{
                name/
                <td colspan="{@colspan}" rowspan="{@rowspan}">{
                    hu:classTd(),
                    <p>{
                        hu:classP(),
                        <code>{string()}</code>
                    }</p>
                 }</td>,
                type/
                <td colspan="{@colspan}" rowspan="{@rowspan}">{
                    hu:classTd(),
                    <p>{
                        hu:classP(),
                        if (not(@linkName/string())) then 
                            <code>{string()}</code> 
                        else
                            <em>+<a shape="rect" href="{@linkName}" 
                                    title="{string()}">{string()}</a></em>, 
                            @substitutionGroup[string()] 
                            ! ('(', <em>↔ {string()}</em>, ')')
                    }</p>
                }</td>,
                anno/
                <td colspan="{@colspan}" rowspan="{@rowspan}">{
                    hu:classTd(),
                    <p>{
                        hu:classP(),
                        string()
                    }</p>
                }</td>
            }</tr>
        }</tbody>
    }</table>
};

(:
 :    I n d e x 
 :    =========
 :)
 
 (:~
 : Writes an HTML index page, which is an entry point for
 : the XSD Content Report.
 :)
declare function hl:contabReportIndex(
                                $domains as element()*, 
                                $options as map(xs:string, item()*))
        as element(html) {
    let $reportType := $options?reportType
    let $odir := $options?odir
    let $pageDir := $odir||'/'||$reportType
    let $fileName := $reportType||'-index.html'
    let $filePath := $pageDir||'/'||$fileName
    let $title := <h1>{cu:systemTitleNodes('contab', $options?custom, $options)}</h1>
    let $head := hl:contabReport_head($filePath, (), $options)
    let $toc := hl:contabReportIndex_toc($filePath, $domains, $options)    
    let $htmlReport :=
        <html lang="en" xml:lang="en">{        
            $head,
            <body>{
                <div id="header">{
                    $title,
                    $toc                      
                }</div>,
                <div id="content">{
                }</div>
           }</body>
       }</html>
       ! u:prettyNode(.)
       
    let $_WRITE := u:writeXmlDoc($filePath, $htmlReport)
       
    return $htmlReport       
};

(:~
 : Constructs the table of content displayed by the
 : XSD Content Report index page.
 :)
declare function hl:contabReportIndex_toc(
                              $filePath as xs:string,
                              $domains as element()*,
                              $options as map(xs:string, item()*)?)
        as element() {
    let $dirPath := $filePath ! fu:getParentPath(.)
    let $reportType := $options?reportType
    
    let $domainDict := map:merge(
        for $domain in $domains
        let $filePath := dm:getReportPath('contab', $domain, $options)
        let $relPath := fu:getRelPath($dirPath, $filePath)        
        let $fileName := $relPath ! file:name(.)
        let $title := $domain/processing/title/string()
        let $enumPath := 
            dm:getReportPartPath('contab', 'enum-dict', $domain, $options)[file:exists(.)]
        let $enumRelPath := $enumPath ! fu:getRelPath($dirPath, .)            
        let $enumFileName := $enumRelPath ! file:name(.)    
        let $countEnumTypes := 
            $enumPath ! doc(.)//div[@class eq 'enum-type-definition'] => count()        
        return (
            map:entry($relPath, map{
            'filePath': $filePath,
            'fileName': $fileName,
            'relPath': $relPath,
            'title': $title
            }),
            map:entry($enumRelPath, map{
            'filePath': $enumPath,
            'fileName': $enumFileName,
            'relPath': $enumRelPath,
            'title': $title||' (enumerations)',
            'countEnumTypes': $countEnumTypes
            })[$enumPath]
        ))
    let $relPaths := map:keys($domainDict) => sort()
    let $ftree := fu:ftree($relPaths, $dirPath)
    let $linkTree := hl:contabReportIndex_tocTree($ftree, $domainDict, $options)
    let $title := 'Table of Contents'
    let $subtitle :=        
        let $reportLabel := 
            if ($options?domainType eq 'xsd') then 'XSD reports' else 'reports'
        return count($domains)||' '||$reportLabel
    let $_DEBUG := dg:WRITE_FILE($ftree, 'FTREE.XML', 'ftree', 'yes', $options)
    return
    
    <div class="toc" id="toc">
        <div id="toctitle">
            <h4>{$title}</h4>
            <p class="tocsubtitle">{$subtitle}</p>
        </div>
        <ul class="sectlevel1">{
          $linkTree
        }</ul>
    </div>
};

(:~
 : Maps a folder tree representation of report files to
 : a sequence of list item elements representing folders
 : and files
 :
 : @param ftree folder tree 
 : @param domainDict maps paths to domain information
 : @param options options controlling the processing
 :)
declare function hl:contabReportIndex_tocTree(
                              $ftree as element(fo),
                              $domainDict as map(xs:string, item()*),
                              $options as map(xs:string, item()*)?)
        as element(li)* {
    hl:contabReportIndex_tocTreeREC($ftree, $domainDict, $options)
};

declare function hl:contabReportIndex_tocTreeREC(
                              $n as node(),
                              $domainDict as map(xs:string, item()*),
                              $options as map(xs:string, item()*)?)
        as element()* {
    typeswitch($n)
    case element(fo) return
        let $level := count($n/ancestor::fo)
        let $prefix := (for $i in 1 to $level return '>> ') => string-join('')
        return (
            <li>{
                <span class="monospace">{$prefix}</span>,
                <span class="darkbrown">{$n/@name/string()}</span>
            }</li>,
            $n/* ! hl:contabReportIndex_tocTreeREC(., $domainDict, $options)
        )
    case element(fi) return
        let $href := $n/ancestor-or-self::*/@name => string-join('/')    
        let $isEnumDict := contains($href, 'enum-dict')
        return if ($isEnumDict and not($options?withEnumDict)) then () else
        
        let $path := $n/ancestor-or-self::*/@name => string-join('/')
        let $level := count($n/ancestor::fo)
        let $prefix := (for $i in 1 to $level return '.  ') => string-join('')
        let $dinfo := $domainDict($path)
        let $href := $dinfo?relPath
        let $title := $dinfo?fileName||
                      ($dinfo?countEnumTypes[string()] ! (' ('||.||')'))
        let $titleClass := attribute class {'enum-dict'} 
                           [contains($href, 'enum-dict')]
        return
            <li>{
                <span class="monospace">{$prefix}</span>,
                <a shape="rect" href="{$href}">{$titleClass, $title}</a>
            }</li>
    default return ()            
};

(:
 :    E n u m    d i c t 
 :    ==================
 :)

(:~
 : Transforms an edesc report or report domain into an contab report. 
 :
 : If no domains have been defined, the function creates the complete
 : report, otherwise the part corresponding to a single domain.
 :
 : @param report an edesc report, complete or limited to a domain
 : @param domain an element describing the domain
 : @param options options controlling the processing
 : @return edesc html report, or a part of the report dealing with a domain
 :)
declare function hl:enumDict_domain(
                                    $report as element(),
                                    $domain as element(domain)?,
                                    $options as map(xs:string, item()*)?)
        as element()? {
    if (not($report//z:enumeration)) then () else
    
    let $_DEBUG := trace($options?withEnumDict, '_______________________WITH_ENUM_DICT: ')
    
    let $reportFilePath := dm:getReportPartPath('contab', 'enum-dict', $domain, $options)
    let $_DEBUG := trace($reportFilePath, '_REPORT_FILE_PATH: ')
    let $head := hl:contabReport_head($reportFilePath, $domain, $options)
    let $enumTypes := eu:getEdescReportEnumTypes($report)
    let $toc := hl:contabReport_enumDict_toc($enumTypes, $domain, $options)    
    let $enumDivs :=
        for $stype in $enumTypes
        let $lname := $stype/
            (@z:name/replace(., '.+:', ''), u:getLocalTypeLabel(., $options?nsmap, $options))[1] 
        let $globalOrLocal := if ($stype/@z:typeID) then 2 else 1
        order by $globalOrLocal, $lname
        count $pos
        return hl:enumDict_stype($stype, $pos, $domain, $options)
    let $title := ($domain/processing/titleEnumDict/<h1>{node()}</h1>, 
                  <h1>{'Enumeration Dictionary ('||$domain/@name||')'}</h1>)[1]
    let $htmlReport :=
        <html lang="en" xml:lang="en">{        
            $head,
            <body>{
                <div id="header">{
                    $title,
                    $toc                      
                }</div>,
                <div id="content">{
                    $enumDivs
                }</div>
           }</body>
       }</html>
       ! u:prettyNode(.)
       
    let $_WRITE :=
        let $reportPath := dm:getReportPartPath('contab', 'enum-dict', $domain, $options)
        where ($reportPath)
        return u:writeXmlDoc($reportPath, $htmlReport)
       
    return $htmlReport       
};

(:~
 : Returns a <div> element containing a TOC.
 :)
declare function hl:contabReport_enumDict_toc(
                              $enumTypes as element()*,
                              $domain as element(domain)?,                              
                              $options as map(xs:string, item()*)?)
        as element() {
    let $custom := $options?custom
    let $xsdDict := $options?schemas return
    
    <div class="toc" id="toc">
        <div id="toctitle">Table of Contents - Enumeration types</div>
        <ul class="sectlevel1">{
            for $type at $tnr in $enumTypes
            let $typeName := $type/@z:name/string()
            let $typeId := $type/@z:typeID/string()
            let $typeLabel := $type/u:getDescriptorLocalTypeLabel(.)
            let $displayName := ($typeName, $typeLabel)[1]
            let $lname := (replace($typeName, '.+:', ''), $typeLabel)[1]
            let $anno := 
                let $raw := $type/z:annotation/z:documentation/normalize-space(.)
                            ! replace(., '(.*?\.).*', '$1')
                return
                    if ($raw) then $raw
                    else if ($typeId) then '(Local type without documentation)'
                    else '(Without documentation)'
            let $href := 
                if ($typeName) then '#enum.'||$typeName
                else '#local-enum.'||$typeId
            let $globalOrLocal := if ($typeId) then 2 else 1                
            order by $globalOrLocal, $lname
            count $tnr
            return
                <li>{
                    <a shape="rect" href="{$href}">{$tnr}. {$displayName}</a>,
                    text{' - '}, 
                    <em>{$anno}</em>
               }</li>
        }</ul>
    </div>
};

declare function hl:enumDict_stype(
                                    $stype as element(z:simpleType),
                                    $typePos as xs:integer,
                                    $domain as element(domain)?,
                                    $options as map(xs:string, item()*)?)
        as element() {
    let $custom := $options?custom        
    let $typeName := $stype/@z:name
    let $typeId := $stype/@z:typeID
    let $typeLabel := $stype/u:getDescriptorLocalTypeLabel(.)
    let $divId := if ($typeName) then 'enum.'||$typeName else 'local-enum.'||$typeId
    let $anno := $stype/z:annotation/z:documentation/normalize-space(.)
    let $compDisplayName := 
        if ($typeLabel) then $typeLabel
        else
            cu:customComponentName(
                $typeName, 'simpleType', 'main', 'contab', $domain/@id, $custom)    
    return
    <div class="enum-type-definition" id="{$divId}">{
        <h3>{$typePos}. {$compDisplayName}</h3>,
        <div class="sectionbody">{
            <table class="tableblock frame-all grid-all spread">
                <colgroup span="1">
                    <col span="1" style="width:28%"/>
                    <col span="1" style="width:72%"/>
                </colgroup>
                <tbody>{
                    <tr>
                        <td colspan="2">{
                            hu:classTd(),
                            <p>{hu:classP(), <span class="darkbrown">{$anno}</span>}</p>
                        }</td>
                    </tr>,
                    for $enum in $stype//z:enumeration
                    let $value := $enum/@z:value/string()
                    let $anno := 
                        ($enum/z:annotation/z:documentation/normalize-space(.), '-')[1]
                    return
                        <tr>{
                            <td class="tableblock halign-left valign-top">
                                <p class="tableblock">
                                    <strong><code>{$value}</code></strong>
                                </p>
                            </td>,
                            <td class="tableblock halign-left valign-top">
                                <p class="tableblock darkbrown">{$anno}</p>
                            </td>
                        }</tr>
                }</tbody>
            </table>
        }</div>
    }</div>
};

