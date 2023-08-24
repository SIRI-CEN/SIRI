(:
 : xco-reporter - funcgtions creating reports
 :)
module namespace rp="http://www.parsqube.de/ns/xco/reporter";

import module namespace df="http://www.parsqube.de/ns/xco/def"
    at "xco-def.xqm";

import module namespace dm="http://www.parsqube.de/ns/xco/domain"
    at "xco-domain.xqm";

import module namespace ed="http://www.parsqube.de/ns/xco/edesc"
    at "xco-edesc.xqm";

import module namespace rd="http://www.parsqube.de/ns/xco/rdesc"
    at "xco-rdesc.xqm";

import module namespace cd="http://www.parsqube.de/ns/xco/desc"
    at "xco-desc.xqm";

import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
at "xco-namespace.xqm";

import module namespace u="http://www.parsqube.de/ns/xco/util"
    at "xco-util.xqm";

import module namespace dg="http://www.parsqube.de/ns/xco/debug"
    at "xco-debug.xqm";

import module namespace hl="http://www.parsqube.de/ns/xco/html"
    at "xco-html.xqm";

import module namespace sf="http://www.parsqube.de/ns/xco/string-filter"
    at "xco-sfilter.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:
 :
 :     e d e s c    r e p o r t
 :     ========================
 :)
(:~
 : Create an edesc report. It contains expanded component descriptors.
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas schemas to be evaluated
 : @param options options controlling the processing
 : @return a report
 :)
declare function rp:expandedCompDescsReport(
                            $comps as element()*,
                            $nsmap as element(z:nsMap),
                            $schemas as element(xs:schema)*,
                            $options as map(xs:string, item()*))
        as element()? {
    let $forEachDomain := exists($options?domains)  (: $options?forEachDomain :)
    return
        (: Write one file for each domain :)
        if ($forEachDomain) then ( 
            let $_LOG := 'Going to write edesc report files for each domain'        
            let $_WRITE := ed:writeExpandedCompDescsPerDomain($comps, $nsmap, $schemas, $options)
            let $_LOG := 'edesc report files written for each domain'
            return ()
        )
        (: Write a single file (if $options?ofile), or return the report :)        
        else
        
    let $ofile := $options?ofile
    (: Create expanded component descriptors :)
    let $reports := 
        ed:getExpandedCompDescs($comps, $nsmap, $schemas, $options)
    let $_DEBUG := trace('*** Expanded component descriptors written ')        
    let $creports :=
        if ($options?skipAnno) then $reports/u:removeAnno(.)/u:prettyNode(.)
        else $reports
    (: Create schema reports :)
    let $schemaReports :=        
        for $crs in $creports
        group by $baseUri := $crs/base-uri(.)
        return
            <z:schema xml:base="{$baseUri}" filePath="{$baseUri ! u:normalizeUri(., ())}">{
                if ($options?skipAnno) then () else
                let $schema := $schemas[base-uri(.) eq $baseUri]
                return $schema/xs:annotation[1]/cd:annotationDescriptor(.),
                <z:components count="{count($crs)}">{$crs}</z:components>
            }</z:schema>
    (: Integrate schema reports :)    
    let $reportRaw :=
        <report reportType="edesc"
                countComponents="{count($creports)}"
                countSchemas="{count($schemaReports)}"
                xmlns:z="http://www.parsqube.de/ns/xco/structure">{
           $schemaReports
        }</report>
        /ns:addNamespaceContext(., $nsmap, ())  /u:prettyNode(.)
    (: Optional grouping by domains :)
    let $reportDomains := 
        rp:expandedCompDescsReport_groupByDomains($reportRaw, $options) 
    (: Perform pruning :)
    let $report :=
        let $skipAtts := $options?skipAtts
        let $keepAtts := $options?keepAtts
        return
            if (empty(($skipAtts, $keepAtts))) then $reportDomains
            else u:removeZAtts($reportDomains, $keepAtts, $skipAtts)
    let $_DEBUG := trace('ofile='||$ofile||
                         '; #elems(reportRaw)='||count($reportRaw//*)||
                         '; count(reports)='||count($reports)||
                         '; count(schemaReports)='||count($schemaReports)||
                         '; #elems(reportDomains)='||count($reportDomains//*)||
                         '; #elems(report)='||count($report//*))
    return 
    (: Either write file or return the report :)
        if ($ofile) then file:write($ofile, $report, map{'indent': 'yes'})
        else $report        
}; 

(:~
 : Edits an edesc report, grouping the schema reports by domain
 : and wrapping them in <domain> elements.
 :)
declare function rp:expandedCompDescsReport_groupByDomains(
                            $report as element(),
                            $options as map(xs:string, item()*))
        as element(report) {
    let $domains := $options?domains
    return if (not($domains)) then $report else
    
    let $domainReports :=
        let $xsdMap := map:merge($report/z:schema/map:entry(@filePath, .))
        for $domain in $domains/domain
        let $xsds := $domain/content/xsd
        order by $domain/@name ! lower-case(.)
        return
            $domain/<z:domain>{
                ns:getNamespaceNodes($report),
                attribute z:name {@name},
                attribute z:id {@id},
                attribute countXsds {count($xsds)},
                for $xsd in $xsds
                let $fpath := $xsd/@filePath
                let $xsdReport := $xsdMap($fpath)
                return $xsdReport
            }</z:domain>
    return
        element {node-name($report)} {
            ns:getNamespaceNodes($report),
            $report/@*,
            attribute countDomains {count($domainReports)},
            $domainReports
        }
};

(:
 :
 :     r d e s c    r e p o r t
 :     ========================
 :)
(:~
 : Creates an rdesc report. Each component is described by a component
 : descriptor accompanied by a complete set of directly or indirectly 
 : referenced other component descriptors. This report format is used
 : as an intermediate when creating expanded component descriptors.
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas schemas to be evaluated
 : @param options options controlling the processing
 : @return a report
 :)
declare function rp:requiredCompDescsReport(
                            $comps as element()*,
                            $nsmap as element(z:nsMap),
                            $schemas as element(xs:schema)*,
                            $options as map(xs:string, item()*))
        as element() {
    let $_DEBUG := trace('RDESC-REPORT: #comps='||count($comps))
    let $reports1 := $comps ! rd:getRequiredCompDescs(., $nsmap, $schemas, $options)
    let $_DEBUG := trace('RDESC-REPORT: reports1 created')
    let $reports2 := $reports1 ! rp:requiredCompDescsElement(.)
    let $_DEBUG := trace('RDESC-REPORT: reports2 created')
    let $reports := $reports2
    let $creports :=
        if ($options?skipAnno) then $reports/u:removeAnno(.)/u:prettyNode(.)
        else $reports/u:prettyNode(.)
    let $_DEBUG := trace('Reports cleaned')        
    let $report :=
        <report reportType="rdesc"
                count="{count($creports)}"
                xmlns:z="http://www.parsqube.de/ns/xco/structure">{
           $creports
        }</report>/ns:addNamespaceContext(., $nsmap, ())
    return $report        
}; 

(:
 :
 :     d e s c    r e p o r t
 :     ======================
 :)
(:~
 : Creates a desc report. Each component is described by a component
 : descriptor. Referenced components are not resolved.
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas schemas to be evaluated
 : @param options options controlling the processing
 : @return a report
 :) 
declare function rp:compDescsReport(
                            $comps as element()*,
                            $nsmap as element(z:nsMap),
                            $schemas as element(xs:schema)*,
                            $options as map(xs:string, item()*))
        as element()? {
    let $reports := $comps ! cd:getCompDescs(., $nsmap, $options)
    let $creports :=
        if ($options?skipAnno) then $reports/u:removeAnno(.)/u:prettyNode(.)
        else $reports/u:prettyNode(.)
    let $report :=
        <report reportType="desc"
                count="{count($creports)}"
                xmlns:z="http://www.parsqube.de/ns/xco/structure">{
           $creports
        }</report>/ns:addNamespaceContext(., $nsmap, ())
    let $ofile := $options?ofile        
    return
    (: Either write file or return the report :)
        if ($ofile) then file:write($ofile, $report, map{'indent': 'yes'})
        else $report        
    
}; 

(:
 :
 :     d e f    r e p o r t
 :     ====================
 :)
(:~
 : Creates a def report. The components contains the selected
 : schema comonents in normalized form.
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas schemas to be evaluated
 : @param options options controlling the processing
 : @return a report
 :)
 
declare function rp:compDefReport(
                            $comps as element()*,
                            $nsmap as element(z:nsMap),
                            $schemas as element(xs:schema)*,
                            $options as map(xs:string, item()*))
        as element()? {
    let $forEachDomain := exists($options?domains)
    return
        (: Write one file for each domain :)
        if ($forEachDomain) then ( 
            let $_LOG := 'Going to write def report files for each domain containing selected components'        
            let $_WRITE := df:writeCompDefDomainReports($comps, $nsmap, $schemas, $options)
            let $_LOG := 'def report files written for each domain'
            return ()
        )
        (: Write a single file (if $options?ofile), or return the report :)        
        else
            df:writeCompDefReport($comps, $nsmap, $schemas, $options)
}; 

(:
 :     c o n t a b    r e p o r t
 :     ==========================
 :)
declare function rp:contabReport(
                            $comps as element()*,
                            $nsmap as element(z:nsMap),
                            $schemas as element(xs:schema)*,
                            $options as map(xs:string, item()*))
        as item()* {
    let $edescReport := $options?edescReport  
    let $edescReportDir := $options?edescReportDir
    let $edescReportDirDynamic := $options?edescReportDirDynamic
    let $useOptions := map:put($options, 'skipAnno', false())
    (: The underlying edesc report is either retrieved or created :)
    let $xmlReportDir := ($edescReportDir, $edescReportDirDynamic)[1]
    let $xmlReport :=
        if ($edescReportDir) then ()
        else if ($edescReport) then
            let $uri := $edescReport ! u:normalizeUri(., ())
            return
                if (not(file:exists($uri))) then error((), 'ERROR - edesc report file not found: ', $uri)
                else if (not(doc-available($uri))) then error((), 'ERROR - cannot read edesc report file: ', $uri)
                else 
                    let $report := doc($uri)/*
                    let $_DEBUG := trace('*** edesc report read from file: '||$uri)
                    return $report
        else
            let $_DEBUG := trace('Write edesc report(s)')
            let $report := rp:expandedCompDescsReport($comps, $nsmap, $schemas, $useOptions)
            let $_DEBUG := trace('Writing of edesc report(s) finished')
            return $report
    let $_WDEBUG := $xmlReport ! dg:WRITE_FILE(., 'EDESC-REPORT.XML', 'edesc-report', 'yes', $options)
    let $_LOG := trace('Write contab reports')
    let $htmlReport := hl:htmlReport('contab', $xmlReport, $xmlReportDir, $options) ! u:prettyNode(.)
    let $_LOG := trace('Writing of contab reports fininshed')
    return ()
}; 

(:
 :     U t i l i t i e s
 :     ==================
 :)
 
(:~
 : Maps a requiredCompDescs map to an element.
 :)
declare function rp:requiredCompDescsElement($reqCompDescsMap as map(xs:string, item()*))
        as element(report) {
    <report>{
        <main>{$reqCompDescsMap?main}</main>,
        <required>{
            for $key in $reqCompDescsMap?required ! map:keys(.)
            order by $key
            let $compDescs := $reqCompDescsMap?required($key)
            let $count := count($compDescs)
            return
                element {$key||'s'} {attribute count {$count}, $compDescs}
        }</required>
    }</report>
};        

        