(:

 : xco-comp-descriptor - functions creating expanded component descriptors.
 :)
module namespace ed="http://www.parsqube.de/ns/xco/edesc";

import module namespace rd="http://www.parsqube.de/ns/xco/rdesc"
  at "xco-rdesc.xqm";
import module namespace cd="http://www.parsqube.de/ns/xco/desc"
  at "xco-desc.xqm";
import module namespace cn="http://www.parsqube.de/ns/xco/comp-names"
  at "xco-comp-names.xqm";
import module namespace co="http://www.parsqube.de/ns/xco/constants"
  at "xco-constants.xqm";
import module namespace dc="http://www.parsqube.de/ns/xco/dcache"
  at "xco-dcache.xqm";
import module namespace dm="http://www.parsqube.de/ns/xco/domain"
  at "xco-domain.xqm";
import module namespace eu="http://www.parsqube.de/ns/xco/edesc-util"
  at "xco-edesc-util.xqm";
import module namespace fu="http://www.parsqube.de/ns/xco/file-util"
  at "xco-file-util.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
  at "xco-namespace.xqm";
import module namespace sd="http://www.parsqube.de/ns/xco/simple-type-description"
  at "xco-stype-description.xqm";
import module namespace u="http://www.parsqube.de/ns/xco/util"
  at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:
 :    P r o c e s s i n g    d o m a i n s    a n d    s e q u e n c e s
 :    ==================================================================
 :)

(:~
 : Writes for each domain an edesc report file.
 :
 : Care is taken to fill and use a cache containing expanded
 : component descriptors. To achieve this, a nested fold-left
 : processing is used, in which the cache is part of the
 : accumulators (outer and inner level).
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas the schemas to be evaluated
 : @param options options controlling the processing
 : @return empty sequence
 :)
declare function ed:writeExpandedCompDescsPerDomain(
                                $comps as element()*,
                                $nsmap as element(z:nsMap),
                                $schemas as element(xs:schema)*,
                                $options as map(xs:string, item()*))
        as item()? {
    let $domains := $options?domains/domain
    return if (not($domains)) then () else
    
    (: Optimization - process all simple types first :)
    let $stypes := $comps/self::xs:simpleType
    let $_OPTIM :=
        if (count($stypes) gt 10) then
            let $_DEBUG := trace('*** Optimization - cache all simple types ('||count($stypes)||')')
            let $_ACTION := ed:foldLeftGetExpandedCompDescs($stypes, $nsmap, $schemas, $options)
            let $_DEBUG := trace('*** Optimization finished')
            return ()
            
    (: Create a sequence of "domain - component maps" describing the domains:
     :     domain: domain-element 
     :     comps: component elements
     : These maps are used as items (!) by fold-left processing.
     :)
    let $domainCompMaps := dm:getDomainComponentMaps($comps, $domains, $schemas, $options)
    
    (: fold-left processing of the maps :)
    let $fnProcessDomain := function($accum, $domainCompMap) {
        let $options := $accum?options
        let $domain := $domainCompMap?domain
        let $comps := $domainCompMap?comps

        (: Nested fold-left processing :)
        let $nestedAccum := ed:foldLeftGetExpandedCompDescs($comps, $nsmap, $schemas, $options)
        (: Updated options (containing updated cache) :)
        let $options2 := $nestedAccum?options
        (: Extract and augment expanded component descriptors :)
        let $edescs := 
            let $prelim := $nestedAccum?edesc
            return ed:getExpandedCompDescs_addTypeDescriptions($prelim, $options2)
        
        (: Updated accumulator contains updated options containing updated cache :)
        let $accum2 := map:put($accum, 'options', $options2)

        (: Create schema reports: 
        :    descriptors are grouped by schema and wrapped in schema elements :)
        let $schemaReports :=        
            for $edesc in $edescs
            group by $baseUri := $edesc/base-uri(.) ! u:normalizeUri(., ())
            return
                <z:schema xml:base="{$baseUri}" filePath="{$baseUri}">{
                    if ($options?skipAnno) then () else
                    let $schema := $schemas[base-uri(.) eq $baseUri]
                    return $schema/xs:annotation[1]/cd:annotationDescriptor(.),
                    <z:components count="{count($edesc)}">{$edesc}</z:components>
                }</z:schema>
                
        (: Sort schema reports :)
        let $schemaReports := dm:sortSchemaDescriptors(
                                    $schemaReports, 
                                    $domain)
                                    (:
                                    $domain/processing/order/first,
                                    $domain/processing/order/last)
                                     :)
        
        (: Create domain report:
         :   schema reports are wrapped in a domain element :)                
        let $domainReport :=
            let $prelim :=
                <z:domain z:name="{$domain/@name}" 
                          z:id="{$domain/@id}" 
                          countXsds="{count($schemaReports)}">{
                    $schemaReports 
                }</z:domain>
                /ns:addNamespaceContext(., $nsmap, ()) 
                /u:prettyNode(.)
            return
                if ($options?skipAnno) then $prelim/u:removeAnno(.)/u:prettyNode(.)
                else $prelim
        let $reportFilePath := dm:getReportPath('edesc', $domain, $options) 
        let $_LOG := trace('*** Write edesc report: '||$reportFilePath)
        let $_WRITE := u:writeXmlDoc($reportFilePath, $domainReport) 
        return $accum2
    }

    (: Initialize accumulator for fold-left processing of domains :)
    let $accum := 
        map{'options': $options, 
            'counter': 1, 
            'nsmap': $nsmap, 
            'schemas': $schemas} 
    let $finalAccum := fold-left($domainCompMaps, $accum, $fnProcessDomain)
    let $options := $finalAccum?options
    return $options
};        

(:~
 : Maps schema components to expanded component descriptors. Uses
 : fold-left and returns the accumulator, a map with two keys:
 : 'edesc' - the component descriptors, 'options' - the updated
 : options map. The options map is updated by updating the cache
 : of expanded component descriptors.
 :
 : @param comps schema components
 : @param nsmap a map of namespace bindings
 : @param schemas the schemas to be evaluated
 : @param options options controlling the processing
 : @return a map with keys 'options' and 'edesc'
 :)
declare function ed:foldLeftGetExpandedCompDescs(
                                         $comps as element()*,
                                         $nsmap as element(z:nsMap),
                                         $schemas as element(xs:schema)*,                                         
                                         $options as map(xs:string, item()*))
        as map(xs:string, item()*) {
       
    (: Sort components in a cache-friendly way :)
    let $sortedComps :=
        for $comp in $comps
        let $lname := $comp/local-name(.)
        let $compName := $comp/ns:normalizedComponentQName(., $nsmap)
        let $kindOrder := 
            switch($lname) 
            case 'simpleType' return 1
            case 'element' return 2            
            case 'group' return 3
            case 'complexType' return 4            
            case 'attribute' return 5
            default return 6
        order by $kindOrder, $compName ! string() ! lower-case(.) 
        return $comp
    
    (: Item processing function of fold-left.
     : @param accum accumulator
     : @param comp a component
     : @return the updated accumulator
     :)
    let $fnGetEdesc := function($accum, $comp) {
        let $optionsAct := $accum?options
        let $rdesc := $comp/rd:getRequiredCompDescs(., $nsmap, $schemas, $optionsAct)
        let $desc := $rdesc?main
        let $descsRequired := $rdesc?required
        let $expanded := ed:expandCompDesc($desc, $descsRequired, $optionsAct)
                         ! ns:addNamespaceContext(., $nsmap, $optionsAct)
        let $optionsAct2 := dc:storeEdesc($expanded, $optionsAct)
        let $accumNew :=
            map:put($accum, 'options', $optionsAct2) !
            map:put(., 'edesc', ($accum?edesc, $expanded))
        return $accumNew   
    }        
    let $accum := map{'options': $options, 'edesc': ()}    
    let $accumFinal := fold-left($sortedComps, $accum, $fnGetEdesc)
    return $accumFinal
};

(:~
 : Maps schema components to expanded component descriptors.
 :
 : @param comps schema components
 : @param nsmap namespace prefix bindings
 : @param schemas XSD schema elements
 : @param options options controlling the processing
 : @return component descriptors
 :)
declare function ed:getExpandedCompDescs($comps as element()*,
                                         $nsmap as element(z:nsMap),
                                         $schemas as element(xs:schema)*,
                                         $options as map(xs:string, item()*))
        as element()* {
    let $cachedAndOthers :=
        for $comp in $comps
        let $edesc := dc:edescForComp($comp, $options)
        return ($edesc, $comp)[1]
    let $cached := $cachedAndOthers/self::z:*
    let $comps := $cachedAndOthers except $cached
    return (
        $cached,
        if (empty($comps)) then () else
    (:    
    let $_DEBUG := 
        trace('*** Starting "getExpandedCompDesc"; count comps: '||count($comps))
     :)   
    (: Process simple types first, in order to get them into the cache :)
    let $sortedComps :=
        for $comp in $comps
        let $lname := $comp/local-name(.)
        let $compName := $comp/ns:normalizedComponentQName(., $nsmap)
        let $kindOrder := 
            switch($lname) 
            case 'simpleType' return 1
            case 'element' return 2            
            case 'group' return 3
            case 'complexType' return 4            
            case 'attribute' return 5
            default return 6
        order by $kindOrder, $compName ! string() ! lower-case(.) 
        return $comp
    
    let $edescAndUpdatedOptions :=
        ed:foldLeftGetExpandedCompDescs($sortedComps, $nsmap, $schemas, $options)
    let $edescs := $edescAndUpdatedOptions?edesc
    let $optionsUpd := $edescAndUpdatedOptions?options
    
    let $result := ed:getExpandedCompDescs_addTypeDescriptions($edescs, $optionsUpd)
    return $result
        )    
};

(:~
 : Augments expanded component descriptors by adding to content items
 : with a simple type a type descriptions.
 :
 : @param edescs expanded component descriptors
 : @param options options ctonrolling the processing; in particular,
 :     containing a cache of component descriptors
 : @return augmented expanded component descriptors
 :)
declare function ed:getExpandedCompDescs_addTypeDescriptions(
                            $edescs as element()*,
                            $options as map(xs:string, item()*))
        as element()* {
    (:
    let $_DEBUG := 
        let $count := $options?dcache?edesc?simpleType ! map:keys(.) => count()
        return trace($count, '*** Add type descriptions: start; #cached simple types: ')
     :)
     
    (: Write dictionaries:
          type name -> type description
          type ID -> type description 
     :)
    let $typeDescGlobalTypeDict :=       
        map:merge(
            for $type in $edescs//@z:type[../@z:typeCategory/starts-with(., 's')]
            let $typeName := string($type)
            group by $typeName
            let $type1 := $type[1]
            let $qname := $type1/resolve-QName(., ..)
            let $edesc := dc:edescForQName($qname, 'simpleType', $options)
            let $typeDesc :=
                if ($edesc) then sd:edescToTypeDescription($edesc)
                else sd:typeNameToTypeDescription($qname, $options?nsmap, $options?schemas?*, $options)
            return map:entry($type1, $typeDesc)
        )
    let $typeDescLocalTypeDict :=       
        map:merge(
            for $typeId in $edescs//@z:typeID[../@z:typeCategory/starts-with(., 's')]
            let $typeIdString := string($typeId)
            group by $typeIdString
            let $typeId1 := $typeId[1]
            let $edesc := $typeId1/../z:simpleType
            let $typeDesc := $edesc/sd:edescToTypeDescription(.)
            return $typeDesc ! map:entry($typeId1, .)
        )
    let $edescsUpd :=
        for $edesc in $edescs
        return
            if (not($edesc//@z:typeCategory[starts-with(., 's')])) then $edesc
            else
            
        copy $edesc_ := $edesc
        modify
            for $tcat in $edesc_//*/@z:typeCategory[starts-with(., 's')]
            where $tcat and not($tcat/../@z:typeDesc)
            let $elem := $tcat/..
            let $type := $elem/@z:type
            let $typeDesc :=
                if ($type) then $typeDescGlobalTypeDict($type)
                else
                    let $typeId := $elem/@z:typeID
                    return $typeId ! $typeDescLocalTypeDict(.)                                
            where $typeDesc
            (: Insert @typeDesc behind @typeCategory :)
            let $typeCatAtt := $elem/@z:typeCategory           
            let $typeDescAtt := attribute z:typeDesc {$typeDesc}
            return
                if ($typeCatAtt) then
                    replace node $typeCatAtt with ($typeCatAtt, $typeDescAtt)
                else insert node $typeDescAtt into $elem
        return $edesc_
        
    return $edescsUpd
};

(:
 :    E x p a n s i o n    o f    a    c o m p.  d e s c.
 :    ===================================================
 :)
(:~
 : Expands component descriptors.
 :
 : @param desc component descriptors
 : @param descsRequired the component descriptors required for expansion
 : @param options options controlling the processing
 : @return component descriptors
 :)
declare function ed:expandCompDesc($desc as element()*, 
                                   $descsRequired as map(xs:string, element()*)?,
                                   $options as map(xs:string, item()*)?)
        as element() {
    ed:expandCompDescREC($desc, $descsRequired, map{}, $options)        
};       

(:~
 : Recursive helper function of `expandCompDesc`.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param visited ?
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
    typeswitch($n)
    case document-node() return document{
        $n/node() ! ed:expandCompDescREC(., $descsRequired, $visited, $options)}
    case element(z:complexType) return    
        ed:expandCompDescREC_complexType($n, $descsRequired, $visited, $options)
    case element(z:simpleType) return 
        ed:expandCompDescREC_simpleType($n, $descsRequired, $visited, $options)
    case element(z:union) return
        ed:expandCompDescREC_union($n, $descsRequired, $visited, $options)
    case element(z:list) return
        ed:expandCompDescREC_list($n, $descsRequired, $visited, $options)
    case element(z:group) return 
        ed:expandCompDescREC_group($n, $descsRequired, $visited, $options)
    case element(z:element) return 
        ed:expandCompDescREC_element($n, $descsRequired, $visited, $options)
    case element() return
        ed:expandCompDescREC_any($n, $descsRequired, $visited, $options)
    case attribute(z:type) return $n
    case attribute() return $n
    default return $n    
};       

(:~
 : Helper function of `expandCompDesc`, processing a "complexType" descriptor.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param visited ?
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC_complexType
                                     ($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
    let $baseAtt := $n/(z:complexContent, z:simpleContent)
                      /(z:extension, z:restriction)
                      /@z:base
    return
        (: Case 1 - no base type :)
        if (not($baseAtt)) then
            element {node-name($n)} {
               $n/@* ! ed:expandCompDescREC(., $descsRequired, $visited, $options),
               $n/node() ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
             }
        else
         
    (: Case 2 with base type :)
    let $ownContent := (
        $n/@* ! ed:expandCompDescREC(., $descsRequired, $visited, $options),
        $baseAtt/../* ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
    )
    let $ownContentAtts := $ownContent/self::attribute()
    let $ownContentChildren := $ownContent except $ownContentAtts
        
    (: Base content is an z:baseType element, optionally followed
     : by z:extension and/or z:restriction elements
     :)
    let $baseContent :=
        let $baseQName := $baseAtt/resolve-QName(., ..)
        let $isBaseBuiltin := ns:isQNameBuiltin($baseQName)
        (: Base type descriptor :)
        let $baseDesc := 
            if ($isBaseBuiltin) then () else
            $descsRequired?type[@z:name/resolve-QName(., ..) eq $baseQName]
        (: "Raw" base content - it may miss a base type wrapper :)
        let $baseContentRaw := 
            let $cached := dc:edescForQName($baseQName, 'type', $options)
            return if ($cached) then $cached else
            $baseDesc ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
        return                    
            (: Wrap base content in an z:baseType element;
                necessary if this type is immediately derived from the ultimate 
                base type
            :)   
            if (not($baseContentRaw/z:baseType)) then 
                <z:baseType>{
                    if ($isBaseBuiltin) then attribute z:name {$baseQName}
                    else (
                        $baseContentRaw/@z:name,
                        $baseContentRaw/@z:typeCategory,
                        $baseContentRaw/*                        
                    )
                }</z:baseType>
            (: Raw base content is already a sequence of z:baseType and 
                 z:extension / z:restriction elements :)
            else $baseContentRaw/*
    return
        element {node-name($n)} {
            $ownContentAtts,
            $baseContent,
            element {$baseAtt/../name()} {
                $n/@z:name,
                $ownContentChildren
            }
        }
};

(:~
 : Helper function of `expandCompDesc`, processing a group element.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC_group
                                     ($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
    let $ref := $n/@z:ref/resolve-QName(., ..)        
    let $viaCache :=
        if (empty($ref)) then ()
        else
            let $cached := dc:edescForQName($ref, 'group', $options)
            return if (not($cached)) then () else 

            let $refAtt := (attribute z:name {$ref}, attribute z:reference {'yes'},
                            attribute z:groupFromCache {'yes'})
            let $atts := $n/(@* except @z:ref) 
                         ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
            let $children := $cached/node()
            return
                element {node-name($n)} {$refAtt, $atts, $children}
    return
        if ($viaCache) then $viaCache else
        ed:expandCompDescREC_any($n, $descsRequired, $visited, $options)
};

(:~
 : Helper function of `expandCompDesc`, processing an element element.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC_element
                                     ($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
    let $ref := $n/@z:ref/resolve-QName(., ..)        
    let $viaCache :=
        if (empty($ref)) then ()
        else
            let $cached := dc:edescForQName($ref, 'element', $options)
            return if (not($cached)) then () else 

            let $refAtt := (attribute z:name {$ref}, attribute z:reference {'yes'},
                            attribute z:elementFromCache {'yes'})
            let $atts := $n/(@* except @z:ref) 
                         ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
            let $atts2 := $cached/(@* except @z:name)
            let $children := $cached/node()
            return
                element {node-name($n)} {$refAtt, $atts, $atts2, $children}
    return
        if ($viaCache) then $viaCache else
        ed:expandCompDescREC_any($n, $descsRequired, $visited, $options)
};

(:~
 : Helper function of `expandCompDesc`, processing unspecific elements.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC_any
                                     ($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
        
    let $name := $n/@z:name/resolve-QName(., ..)
    let $newVisited := 
        if (empty($name)) then $visited else ed:updateVisited($visited, $n, $name)    
    let $typeID := $n/@z:typeID    
    return
        if (exists($name) and not($typeID)) then
            element {node-name($n)} {
                $n/@* ! ed:expandCompDescREC(., $descsRequired, $newVisited, $options),
                $n/node() ! ed:expandCompDescREC(., $descsRequired, $newVisited, $options)
            }
        else
       
    (: Resolve @ref :)
    let $ref := $n/@z:ref/resolve-QName(., ..)
    let $refCyclic := $ref = $visited(local-name($n))
    let $resolvedRef :=
        if (empty($ref) or $refCyclic) then () else 
            $descsRequired(local-name($n))[@z:name/resolve-QName(., ..) eq $ref]
    let $refAtt := 
        if ($resolvedRef) then (attribute z:name {$ref}, attribute z:reference {'yes'})
        else if (exists($ref)) then attribute z:REF-UNRESOLVED {$ref}
        else ()
    let $resolvedRefEdesc := 
        $resolvedRef/ed:expandCompDescREC(., $descsRequired, $newVisited, $options)
    
    (: Resolve @typeID :)
    let $localTypeEdesc := 
        if (not($typeID)) then () else
        let $localTypeDesc := $descsRequired('localType')[@z:typeID eq $typeID]
        return
            $localTypeDesc/ed:expandCompDescREC(., $descsRequired, $visited, $options)    

    (: Resolve @type :)
    let $typeQN := $n/@z:type/resolve-QName(., ..)
    let $type := $n/@z:type/string()
    let $typeCyclic := $typeQN = $visited(local-name($n))    
    let $globalTypeEdesc :=
        if (empty($type) or not($options?deepResolve) or $typeCyclic) then () else 
        let $globalTypeDesc := $descsRequired('type')[@z:type eq $type]
        return 
            $globalTypeDesc/ed:expandCompDescREC(., $descsRequired, $visited, $options)
    
    let $resolvedExpanded := ($resolvedRefEdesc, $localTypeEdesc, $globalTypeEdesc)
    (:
    let $_DEBUG := 
        if (count($resolvedExpanded) le 1) then () else
            trace(count($resolvedExpanded), concat('Kind=', $n/local-name(), '; Name=', $n/@z:name, '; Ref: ', $n/@z:ref, '; Count: '))
     :)            
    let $ownAttNames := ($n/@*, $refAtt)/node-name(.)
    return
        element {node-name($n)} {
            (: Own attributes (minOccurs, maxOccurs, ... :)
            $refAtt,
            $n/@* ! ed:expandCompDescREC(., $descsRequired, $visited, $options),
            attribute CYCLIC_REF {local-name($n)||'='||$ref}[$refCyclic],
            attribute CYCLIC_TYPE {'@type='||$type}[$typeCyclic],
            (: Attributes on referenced component :)
            $resolvedExpanded/(@* except @xml:basex)[not(node-name(.) = $ownAttNames)],
            (: Own child nodes (annotation, ...) :)
            $n/node() ! ed:expandCompDescREC(., $descsRequired, $visited, $options),
            (: Child nodes of referenced component :)
            $resolvedExpanded/(if (node-name(.) eq $n/node-name(.)) then node() else .)
        }
};

(:~
 : Helper function of `expandCompDesc`, processing a "simpleType" descriptor.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC_simpleType
                                     ($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
    let $baseAtt := $n/z:restriction/@z:base
    let $restriction := $baseAtt/..
    let $ownContentAtts := 
        $n/@* ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
    let $stypeTree :=
        (: Case 1 - no base type :)
        if (not($baseAtt)) then
            element {node-name($n)} {
               $ownContentAtts,
               $n/*/ed:expandCompDescREC(., $descsRequired, $visited, $options)
            }
        else
         
        (: Case 2 with base type :)
        let $ownRestriction := 
            $restriction/* ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
        let $baseQName := $baseAtt/resolve-QName(., ..)
        let $faceted :=
            let $baseTypeBuiltin := ns:isQNameBuiltin($baseQName)
            let $baseTypeExpanded := 
                if ($baseTypeBuiltin) then () else
                    $descsRequired?type[@z:name/resolve-QName(., ..) eq $baseQName]
                    ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
            let $baseType :=
                if ($baseTypeBuiltin) then <z:baseType z:name="{$baseQName}" z:typeCategory="sb"/>
                else if ($baseTypeExpanded/z:faceted) then
                    $baseTypeExpanded/z:faceted/z:baseType
                else <z:baseType>{$baseTypeExpanded}</z:baseType>
                   
            let $restrictions := (
                $baseTypeExpanded/z:faceted/z:restrictions/z:restriction,
                <z:restriction>{$n/@z:name, $ownRestriction}</z:restriction>)
            return 
                <z:faceted>{
                    $baseType,
                    <z:restrictions>{$restrictions}</z:restrictions>
                }</z:faceted>
        return
            element {node-name($n)} {
                $n/(* except z:restriction) 
                    ! ed:expandCompDescREC(., $descsRequired, $visited, $options),
                $faceted
            }    
    let $stypeDescription := sd:edescToTypeDescription($stypeTree)
    return
        element {node-name($n)} {
            $ownContentAtts,
            attribute z:typeDesc {$stypeDescription},
            $stypeTree/node()
        }
};

(:~
 : Helper function of `expandCompDesc`, processing a "union" element.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC_union
                                     ($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
    let $memberTypes := $n/@z:memberTypes ! tokenize(.)
    let $memberTypesReferenced :=
        for $memberType in $memberTypes
        let $memberQName := resolve-QName($memberType, $n)
        return
            if (ns:isQNameBuiltin($memberQName)) then 
                <z:builtinType z:name="{$memberType}" z:typeCategory="sb"/>
            else
                let $mtype := $descsRequired?type[@z:name/resolve-QName(., ..) eq $memberQName]
                let $mtypeExpanded := 
                    $mtype ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
                return $mtypeExpanded
    let $memberTypesLiteral :=
        $n/z:simpleType ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
    return
        element {node-name($n)} {
            (
            $memberTypesReferenced,
            $memberTypesLiteral
            ) ! <z:unionMember>{.}</z:unionMember>
        }
};

(:~
 : Helper function of `expandCompDesc`, processing a "list" element.
 :
 : @param n a node to be processed during recursive processing
 : @param descsRequired the component descriptors required for expansion
 : @param options options controlling the processing
 : @return part of a component descriptor
 :)
declare function ed:expandCompDescREC_list
                                     ($n as node(), 
                                      $descsRequired as map(xs:string, element()*)?,
                                      $visited as map(xs:string, xs:QName*),
                                      $options as map(xs:string, item()*)?)                                      
        as node()* {
    let $itemTypeReferenced := 
        let $qname := $n/@z:itemType/resolve-QName(., $n)
        where exists($qname)
        return
            if (ns:isQNameBuiltin($qname)) then 
                <z:itemType z:name="{$qname}" z:typeCategory="'sb'"/>
            else
                $descsRequired?type[@z:name/resolve-QName(., ..) eq $qname]
                ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
                ! <z:itemType>{.}</z:itemType>
    let $itemTypeLiteral :=
        $n/z:simpleType 
        ! ed:expandCompDescREC(., $descsRequired, $visited, $options)
        ! <z:itemType>{.}</z:itemType>
    return
        element {node-name($n)} {
            (
            $itemTypeReferenced,
            $itemTypeLiteral
            )
        }
};

(:~
 : Updates the map of visited components. Keys are component
 : kinds, values are sequences of qualified names.
 : 
 :)
declare function ed:updateVisited($visited as map(xs:string, item()*), 
                                  $comp as element(),
                                  $name as xs:QName)
        as map(xs:string, item()*) {
    let $kind := $comp/local-name(.)
    let $updatedNames := ($visited($kind), $name)
    return map:put($visited, $kind, $updatedNames) 
};
