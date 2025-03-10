(:

 : xco-def.xpm - functions supporting def reports.
 :)
module namespace df="http://www.parsqube.de/ns/xco/def";

import module namespace dm="http://www.parsqube.de/ns/xco/domain"
    at "xco-domain.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
    at "xco-namespace.xqm";
import module namespace u="http://www.parsqube.de/ns/xco/util"
    at "xco-util.xqm";
  
declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Writes for each domain a def report file.
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas the schemas to be evaluated
 : @param options options controlling the processing
 : @return empty sequence
 :)
declare function df:writeCompDefDomainReports(
                                $comps as element()*,
                                $nsmap as element(z:nsMap),
                                $schemas as element(xs:schema)*,
                                $options as map(xs:string, item()*))
        as item()? {
    let $domains := $options?domains/domain
    return if (not($domains)) then () else

    let $domainXsdComponentMaps := 
        dm:getDomainXsdComponentMaps($comps, $domains, $schemas, $options)
    for $domain in $domains
    let $domainXsdComponentMap := $domainXsdComponentMaps[?domain is $domain]
    let $xsdReports :=
        for $filePath in $domainXsdComponentMap?xsds ! map:keys(.)
        let $comps := $domainXsdComponentMap?xsds($filePath)
        where $comps
        let $compsGrouped :=
            for $comp in $comps
            let $kind := $comp/local-name(.)
            group by $kind
            order by $kind
            return
                <z:components kind="{$kind}" count="{count($comp)}">{
                    $comp
                }</z:components>
        order by $filePath
        return
            <xsd filePath="{$filePath}" countComps="{count($comps)}">{
                $compsGrouped
            }</xsd>
    let $countComps := count($xsdReports/z:components/*)
    where $countComps
    let $domainReportRaw :=
        <z:domain z:name="{$domain/@name}" 
                  z:id="{$domain/@id}"
                  countXsds="{count($xsdReports)}"
                  countComps="{$countComps}">{
            for $xsdReport in $xsdReports[@countComps > 0]
            let $filePath := $xsdReport/@filePath
            order by $filePath
            return
                <z:schema xml:base="{$filePath}" 
                          filePath="{$filePath}">{
                    $xsdReport/@countComps,
                    $xsdReport/*
                }</z:schema>
        }</z:domain>/ns:addNamespaceContext(., $nsmap, ())/u:prettyNode(.)
            
    let $domainReport :=
        if ($options?skipAnno) then $domainReportRaw/u:removeAnno(.)/u:prettyNode(.)
        else $domainReportRaw/u:prettyNode(.)
        
    let $reportFilePath := dm:getReportPath('def', $domain, $options) 
    let $_LOG := trace('*** Write def report: '||$reportFilePath)
    let $_WRITE := u:writeXmlDoc($reportFilePath, $domainReport)
    return ()
};

(:~
 : Writes a def report file.
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas the schemas to be evaluated
 : @param options options controlling the processing
 : @return empty sequence
 :)
declare function df:writeCompDefReport(
                                $comps as element()*,
                                $nsmap as element(z:nsMap),
                                $schemas as element(xs:schema)*,
                                $options as map(xs:string, item()*))
        as item()? {
    let $ofile := $options?ofile
    let $reports := 
        for $comp in $comps
        let $filePath := $comp/base-uri(.) ! u:normalizeUri(., ())
        group by $filePath
        order by $filePath
        let $compsGrouped :=
            for $comp2 in $comp
            let $kind := $comp2/local-name(.)
            group by $kind
            order by $kind
            return
                <z:components kind="{$kind}" count="{count($comp2)}">{
                    $comp2
                }</z:components>
        return
            <z:schema filePath="{$filePath}" xml:base="{$filePath}" countComps="{count($comp)}">{
                $compsGrouped
            }</z:schema>
    let $creports :=
        if ($options?skipAnno) then $reports/u:removeAnno(.)/u:prettyNode(.)
        else $reports/u:prettyNode(.)
    let $report :=
        <z:report reportType="def" count="{count($creports)}">{
           $creports
        }</z:report>/ns:addNamespaceContext(., $nsmap, ())
    return 
    (: Either write file or return the report :)
        if ($ofile) then (
            file:write($ofile, $report, map{'indent': 'yes'}),
            trace((), 'Report file written: '||$ofile))
        else $report        
};        
