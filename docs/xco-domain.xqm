(:
 : Functions evaluating domains defined by the customization document.
 :)
module namespace dm="http://www.parsqube.de/ns/xco/domain";

import module namespace co="http://www.parsqube.de/ns/xco/constants"
    at "xco-constants.xqm";

import module namespace dg="http://www.parsqube.de/ns/xco/debug"
    at "xco-debug.xqm";

import module namespace fu="http://www.parsqube.de/ns/xco/file-util"
    at "xco-file-util.xqm";

import module namespace sd="http://www.parsqube.de/ns/xco/simple-type-description"
    at "xco-stype-description.xqm";

import module namespace sf="http://www.parsqube.de/ns/xco/string-filter"
    at "xco-sfilter.xqm";

import module namespace u="http://www.parsqube.de/ns/xco/util"
   at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

declare variable $dm:findComps :=
    map{
        'type': function($domain, $namespace, $name) {
                    $domain//xsd[@targetNamespace eq $namespace]
                    //(simpleTypes/simpleType, complexTypes/complexType)[@name eq $name]},
        'group': function($domain, $namespace, $name) {
                    $domain//xsd[@targetNamespace eq $namespace]        
                    //groups/group[@name eq $name]},
        'attributeGroup': function($domain, $namespace, $name) {
                    $domain//xsd[@targetNamespace eq $namespace]
                    //attributeGroups/attributeGroup[@name eq $name]},
        'element': function($domain, $namespace, $name) {
                    $domain//xsd[@targetNamespace eq $namespace]        
                    //elements/element[@name eq $name]},
        'attribute': function($domain, $namespace, $name) {
                    $domain//xsd[@targetNamespace eq $namespace]        
                    //attributes/attribute[@name eq $name]}
    };

(:
 :
 :    I n t e r f a c e    f u n c t i o n s
 :)
(:~
 : Returns the file system path of a report with a given report type.
 : The file path refers to the main report with that type. In order to 
 : retrieve the file system path of other parts of a report (e.g. the
 : enum dictionary), call 'getReportPartPath'.
 
 :
 : @param reportType a report type
 : @param an optional domain element
 : @param options options controlling the processing
 : @return file system path of the main report with that type
 :)
declare function dm:getReportPath($reportType as xs:string, 
                                  $domain as element()?,
                                  $options as map(xs:string, item()*))
        as xs:string {
    (: Explicit 'ofile' parameter overwrites any domain settings :)
    let $ofile := $options?ofile
    let $reportTypeFinal := $options?reportType
    let $path :=
        if ($ofile and $reportType eq $reportTypeFinal) then $ofile
        
        (: No domain - default path depending on 'odir' and the report type :)
        else if (not($domain)) then 
            let $odir := $options?odir
            let $fname := dm:reportTypeDefaultFileName($reportType)
            return $odir||'/'||$reportType||'/'||$fname
            
        (: File path is retrieved from the compiled domain element :)
        else
            let $odir := $options?odir        
            let $reportDirRelPath := $domain/processing/reportDirRelPath[string()]
            let $reportFileBaseName := $domain/processing/reportFileBaseName
            let $fileExtension := dm:reportTypeFileNameExtension($reportType)
            let $relPath := $reportDirRelPath ! concat(., '/')
            return $odir||'/'||$reportType||'/'||$relPath||
                   $reportFileBaseName||'.'||$fileExtension
    (: let $_DEBUG := trace($path, 'RPATH FOR: ***RTYPE='||$reportType||';DOM='||$domain/@name||': ') :)                   
    return $path                   
};

(:~
 : Returns the file system path of a report with a given report type
 : and containing a part of the report with a given part name.
 :
 : @param reportType a report type
 : @param reportPart a named part of the reporgt, e.g. 'enum-dict'
 : @param an optional domain element
 : @param options options controlling the processing
 : @return file system path of the main report with that type
 :)
declare function dm:getReportPartPath($reportType as xs:string,
                                      $reportPart as xs:string?,
                                      $domain as element()?,
                                      $options as map(xs:string, item()*))
        as xs:string {
    let $mainReportPath := dm:getReportPath($reportType, $domain, $options)
    return
        if (not($reportPart)) then $mainReportPath
        else fu:insertLabelBeforeFileNameExtension($mainReportPath, '.'||$reportPart)
};

(:~
 : Returns the file system path of an input report file.
 :)
declare function dm:getInputReportPath($inputReportType as xs:string,
                                       $inputReportBaseDir as xs:string,
                                       $domain as element(),
                                       $options as map(xs:string, item()*))
        as xs:string {
    let $reportDirRelPath := $domain/processing/reportDirRelPath
    let $reportFileBaseName := $domain/processing/reportFileBaseName
    let $reportFileExtension := dm:reportTypeFileNameExtension($inputReportType)
    return fu:applyRelPath($inputReportBaseDir, $reportDirRelPath)
               ||'/'||$reportFileBaseName||'.'||$reportFileExtension
};

(:~
 : Returns the default file name for a given report type.
 :
 : @param reportType a report type
 : @return the default file name
 :)
declare function dm:reportTypeDefaultFileName($reportType as xs:string)
        as xs:string {
    switch($reportType)
    case 'contab' return 'contab.html'
    default return $reportType||'.xml'
};

(:~
 : Returns the default file name for a given report type.
 :
 : @param reportType a report type
 : @return the default file name
 :)
declare function dm:reportTypeFileNameExtension($reportType as xs:string)
        as xs:string {
    switch($reportType)
    case 'contab' return 'html'
    default return 'xml'
};

(:
 :
 :    C o n s t r u c t    d o m a i n    e l e m e n t s
 :)

(:~
 : Evaluates the definition of domains, returning an extended 
 : representation.
 :
 : @param custom the customization document
 : @param schemas the schema elements to be reported
 : @return an element describing all domains
 :)
declare function dm:constructDomains($customDomains as element()?,
                                     $schemas as element(xs:schema)*,
                                     $options as map(xs:string, item()*))
        as element(domains)? {
    let $domainsParam := $options?domains
    return if (not($domainsParam) and not($customDomains)) then () else
    
    let $schemaDescriptors := $schemas/dm:xsdDescriptor(.)
    let $domainElems := $customDomains/*    
    let $tnsDomains := $domainElems[content/foreach = 'targetNamespace']
    let $xsdDomains := $domainElems[content/foreach = 'xsd']
    let $filterDomains := $domainElems except ($tnsDomains, $xsdDomains)
    return
        if ($tnsDomains) then 
            error((), 'Customized target namespace domains not yet supported.')
        else if ($xsdDomains) then 
            error((), 'Customized XSD domains not yet supported.')
        else
            if ($domainsParam eq 'xsd') then
                dm:createXsdDomains($schemaDescriptors, $options)
            else
                let $domains :=  
                    if (not($filterDomains)) then () else 
                        dm:compileFilterDomains($schemaDescriptors, $filterDomains, $options)        
                return
                    <domains count="{count($domains)}">{$domains}</domains>
};

(:
 :
 :    C o m p i l e    f i l t e r    d o m a i n s
 :)
(:~
 : Compiles custom domain defintions, type "filter domain".
 :)
declare function dm:compileFilterDomains(
                            $schemaDescriptors as element()*,
                            $customDomains as element()+,
                            $options as map(xs:string, item()*))
        as element(domain)* {
    let $activeDomains := $options?activeDomains
    
    for $domain at $pos in $customDomains
    where empty($activeDomains) or $domain/@name = $activeDomains        
    let $tnsPlus :=
        $domain/content/targetNamespace/
            dm:filterSchemaDescriptorsByTns(., $schemaDescriptors)
    let $tnsMinus :=      
        $domain/content/exceptTargetNamespace/
            dm:filterSchemaDescriptorsByFiles(., $schemaDescriptors)
    let $filesPlus := $domain/content/files/
        dm:filterSchemaDescriptorsByFiles(., $schemaDescriptors)
    let $filesMinus := $domain/content/exceptFiles/
        dm:filterSchemaDescriptorsByFiles(., $schemaDescriptors)        
    let $selected := ($tnsPlus, $filesPlus)
        [not(. = ($tnsMinus, $filesMinus))] 
    let $selectedOrdered := 
        dm:sortSchemaDescriptors($selected, $domain) 
    let $id := 'd'||$pos
    let $name := ($domain/@name, $id)[1]
    let $summary := $domain/dm:filterDomainSummary(.)
    return
        <domain id="{$id}"
                name="{$name}"
                def="{$summary}"
                domainType="filter">{
            <content count="{count($selectedOrdered)}">{
                $selectedOrdered
            }</content>,
            dm:compileProcessingElem($domain/processing, $options)                
        }</domain>
};

(:~
 : Filters schema descriptors by target namespace.
 :)
declare function dm:filterSchemaDescriptorsByTns(
                                $tns as xs:string, 
                                $schemaDescriptors as element()*)
        as element()* {
    let $sfilter := sf:compileStringFilter($tns)
    return 
        $schemaDescriptors
            [sf:matchesStringFilter(string(@targetNamespace), $sfilter)]
};

(:~
 : Filters schema descriptors by file name/path constraints.
 :)
declare function dm:filterSchemaDescriptorsByFiles(
                                $files as element(), 
                                $schemaDescriptors as element()*)
        as element()* {                                
    let $dir := $files/@dir
    let $name := $files/@name
    let $nameFilter := sf:compileStringFilter($name)
    let $deep := $files/@deep/xs:boolean(.)
    let $dirFilter :=
        if (starts-with($dir, '/')) then
            if ($deep) then $dir||'(/.*)?$'
            else $dir||'$'
        else if ($deep) then '(.*/)?'||$dir||'(/.*/)?$'
        else  '(.*/)?'||$dir||'$'
    return
        for $schemaDesc in $schemaDescriptors 
        where sf:matchesStringFilter($schemaDesc/@fileName, $nameFilter)
        let $folder := $schemaDesc/@filePath ! file:parent(.) ! u:normalizeUri(., ())
        where matches($folder, $dirFilter, 'i')
        return $schemaDesc
};

declare function dm:filterDomainSummary($domain as element())
        as xs:string {
    let $tns := $domain/content/targetNamespace/concat('tns=', .) => string-join(', ')        
    let $etns := $domain/content/exceptTargetNamespace/concat('~tns=', .) => string-join(', ')
    let $files := $domain/content/files/
        concat('files=[dir=', @dir, ', name=', @name, ', deep=', (@deep, 'false')[1], ']') 
        => string-join(', ')
    let $efiles := $domain/content/exceptFiles/
        concat('~files=[dir=', @dir, ', name=', @name, ', deep=', (@deep, 'false')[1], ']') 
        => string-join(', ')
    return string-join(($tns, $etns, $files, $efiles)[string()], '; ')
};  

(:
 :
 :    C o m p i l e    c u s t o m    d o m a i n s
 :)
(:~
 : Copiles the processing element of custom domain elements.
 :)
declare function dm:compileProcessingElem($processing as element(processing),
                                          $options as map(xs:string, item()*))
        as element(processing) {
    $processing ! dm:compileProcessingElemREC(., $options)        
};

(:~
 : Recursive helper function of `compileProcessingElem`.
 :)
declare function dm:compileProcessingElemREC($n as node(),
                                             $options as map(xs:string, item()*))
        as node()* {
    typeswitch($n)        
    case document-node() return document {$n/node() ! dm:compileProcessingElemREC(., $options)}  
    (: Add elements: <forEachDomain>, <reportRelPath> :)
    case element(processing) return
        let $reportType := $options?reportType
        let $reportDirRelPath := ($n/reportDirRelPath, '')[1]
        let $forEachDomain  := ($options?forEachDomain, false())[1] 
        return
            element {node-name($n)} {
                $n/@* ! dm:compileProcessingElemREC(., $options),
                $n/node() ! dm:compileProcessingElemREC(., $options),
                <forEachDomain>{$forEachDomain}</forEachDomain>,
                <reportDirRelPath>{$reportDirRelPath}</reportDirRelPath>                
            }
    case element(reportDirRelPath) return () (: already processed :)        
    case element(title) return
        let $value := normalize-space($n)
        let $title :=
            if (starts-with($value, '#')) then
                let $key := $value ! substring(., 2)
                return $options($key)
            else $value
        return <title>{$title}</title>
    case element() return 
        element {node-name($n)} {
            $n/@* ! dm:compileProcessingElemREC(., $options),
            $n/node() ! dm:compileProcessingElemREC(., $options)
        }
    case attribute() return $n
    default return $n
};

(:
 :
 :    C r e a t e    X S D    d o m a i n s
 :)
(:~
 : Creates XSD domains, one for each XSD.
 :
 : @param schemaDescriptors schema descriptors
 : @param options options controlling the processing
 : @return XSD domains
 :)
declare function dm:createXsdDomains($schemaDescriptors as element()*,
                                     $options as map(xs:string, item()*))
        as element() {
    let $odir := $options?odir
    let $dir := $options?dir
    return 
        (: Check should have been performed before - here only minimal check :)
        if (not($odir) or not($dir)) then error() else
    
    let $sortedSchemaDescriptors :=
        for $schemaDesc in $schemaDescriptors
        let $filePath := $schemaDesc/@filePath
        order by $filePath
        return $schemaDesc
   
    let $domains :=
        for $schemaDesc at $pos in $sortedSchemaDescriptors
        let $id := 'd'||$pos
        let $filePath := $schemaDesc/@filePath
        let $fileRelPath := fu:getRelPath($dir, $filePath)
        let $fileName := $filePath ! file:name(.)
        let $relParentPath := $fileRelPath ! fu:getRelParentPath(.)
        let $dirInfo := $relParentPath[string()] ! <span class="dir">{.||'/ '}</span>
        let $dirPath := $filePath ! fu:getParentPath(.)
        let $dirRelPath := fu:getRelPath($dir, $dirPath)
        let $fname := $schemaDesc/@fileName        
        let $fileBaseName := $fname ! fu:removeFileExtension(.)
        return
            <domain id="{$id}" 
                    name="{$fname}"
                    def="{'xsd-content('||$fname||')'}">{
                <content count="1">{$schemaDesc}</content>,
                <processing dir="{$dir}" dirPath="{$dirPath}" dirRelPath="{$dirRelPath}">
                    <title>{'Contents: ', $dirInfo, $fileName}</title>
                    <titleEnumDict>{'Enumeration dictionary: '||$fileRelPath}</titleEnumDict>
                    <reportFileBaseName>{$fileBaseName}</reportFileBaseName>
                    <reportDirRelPath>{$dirRelPath}</reportDirRelPath>
                </processing>
            }</domain>
    return
        <domains count="{count($domains)}" 
                 domainType="xsd">{
            $domains
        }</domains>
};

(:
 :    D o m a i n    r e l a t e d    u t i l i t i e s
 :)
 
(:~
 : Maps the domains to a sequence of maps, each one containing
 : a domain element and the components belonging to that domain.
 :
 : Map structure:
 : {
 :     'domain': <domain>...</domain>
 :     'comps': <foo>...</foo>, <bar>...</bar>, ...
 : }
 :
 : @param comps schema components
 : @param domains domain elements, defining domains
 : @param schemas the schemas to be evaluated
 : @param options options controlling the processing
 : @return a sequence of maps
 :)
declare function dm:getDomainComponentMaps(
                          $comps as element()*, 
                          $domains as element(domain)*, 
                          $schemas as element(xs:schema)*,
                          $options as map(xs:string, item()*))
        as map(xs:string, item()*)* {
    let $xsdDict :=
        map:merge(
            for $comp in $comps
            let $xsdpath := $comp/base-uri(.) ! u:normalizeUri(., ())
            group by $xsdpath
            return map:entry($xsdpath, $comp)
        )
    for $domain in $domains
    let $domainComps :=
        for $xsd in $domain/content/xsd
        let $filePath := $xsd/@filePath ! u:normalizeUri(., ())        
        let $xsdComps := $xsdDict($filePath)
        return $xsdComps
    return
        map{'domain': $domain, 'comps': $domainComps}
};

(:~
 : Maps the domains to a sequence of maps, each one containing
 : a domain element and the corresponding components, grouped
 : by containing XSD.
 :
 : Map structure:
 : {
 :     'domain': <domain>...</domain>
 :     'xsds': 
 :         $filePath: <foo>...</foo>, <bar>...</bar>, ...
 : }
 :
 : @param comps schema components
 : @param domains domain elements, defining domains
 : @param schemas the schemas to be evaluated
 : @param options options controlling the processing
 : @return a sequence of maps
 :)
declare function dm:getDomainXsdComponentMaps(
                          $comps as element()*, 
                          $domains as element(domain)*, 
                          $schemas as element(xs:schema)*,
                          $options as map(xs:string, item()*))
        as map(xs:string, item()*)* {
    (: map: xsd-path => components :)
    let $xsdDict :=
        map:merge(
            for $comp in $comps
            let $xsdpath := $comp/base-uri(.) ! u:normalizeUri(., ())
            group by $xsdpath
            return map:entry($xsdpath, $comp)
        )
    for $domain in $domains
    let $xsdComps := map:merge(
        for $xsd in $domain/content/xsd
        let $filePath := $xsd/@filePath ! u:normalizeUri(., ())        
        let $xsdComps := $xsdDict($filePath)
        return map:entry($filePath, $xsdComps))
    return
        map{'domain': $domain, 'xsds': $xsdComps}
};


(:
 :
 :    U t i l i t y    f u n c t i o n s
 :)

(:~
 : Maps an XSD to an element summarizing XSD properties and
 : content.
 :)
declare function dm:xsdDescriptor($schema as element(xs:schema))
        as element() {
    let $filePath := $schema/base-uri(.) ! u:normalizeUri(., ())        
    let $fileName := $filePath ! file:name(.)
    let $tns := $schema/@targetNamespace
    let $stypes := $schema/xs:simpleType/@name/string() => sort()
    let $ctypes := $schema/xs:complexType/@name/string() => sort()
    let $elements := $schema/xs:element/@name/string() => sort()
    let $attributes := $schema/xs:attribute/@name/string() => sort()
    let $groups := $schema/xs:group/@name/string() => sort()
    let $attributeGroups := $schema/xs:attributeGroup/@name/string() => sort()
    return
        <xsd filePath="{$filePath}" 
             fileName="{$fileName}" 
             targetNamespace="{$tns}">{
            <elements count="{count($elements)}">{
                $elements ! <element name="{.}"/>
            }</elements>,
            <attributes count="{count($attributes)}">{
                $attributes ! <attribute name="{.}"/>
            }</attributes>,
            <simpleTypes count="{count($stypes)}">{
                $stypes ! <simpleType name="{.}"/>
            }</simpleTypes>,
            <complexTypes count="{count($ctypes)}">{
                $ctypes ! <complexType name="{.}"/>
            }</complexTypes>,
            <groups count="{count($groups)}">{
                $groups ! <group name="{.}"/>
            }</groups>,
            <attributeGroups count="{count($attributeGroups)}">{
                $attributeGroups ! <attributeGroup name="{.}"/>
            }</attributeGroups>
        }</xsd>
};

(:~
 : Sort schema descriptors. A schema descriptor is an element
 : with an attribute @filePath, containing the file path of
 : a schema.
 :)
declare function dm:sortSchemaDescriptors(
                              $schemaDescriptors as element()*, 
                              $domain as element(domain))
        as element()* {
    let $first := $domain/processing/order/first        
    let $last := $domain/processing/order/last
    return
        if (not(($first, $last))) then
            for $sd in $schemaDescriptors
            order by $sd/@filePath/lower-case(.)
            return $sd 
        else
    
    $schemaDescriptors 
    => dm:sortSchemaDescriptorsFirstOrLast($first) 
    => dm:sortSchemaDescriptorsFirstOrLast($last)        
};

(:~
 : Sorts a sequence of schema descriptors (1) by the position of
 : a matching file path in $firstOrLast, (2) by file path.
 :)
declare function dm:sortSchemaDescriptorsFirstOrLast(
                              $schemaDescriptors as element()*, 
                              $firstOrLast as element()?)
        as element()* {
    if (not($firstOrLast)) then $schemaDescriptors else
    
    let $defaultPos := if ($firstOrLast/self::first) then 100000 else 0
    for $sd in $schemaDescriptors
    let $filePath := $sd/@filePath
    let $pos := 
        let $match := $firstOrLast/xsd[matches($filePath, '(^|/)'||@filePath, 'i')]
        return
            if (not($match)) then $defaultPos
            else count($match/preceding-sibling::xsd) + 1
    (: let $_DEBUG := trace('pos='||$pos||' filePath='||$filePath) :)
    order by $pos, $filePath
    return $sd
};
