module namespace cf="http://www.parsqube.de/ns/xco/comp-finder";

import module namespace u="http://www.parsqube.de/ns/xco/util"
at "xco-util.xqm";
import module namespace sf="http://www.parsqube.de/ns/xco/string-filter"
at "xco-sfilter.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Returns schema components (element declarations, attribute declarations,
 : type definitions, group definitions, attribute group definitions) with a
 : name matching string filters.
 :
 : @param enames a name filter for element declarations
 : @param anames a name filter for attribute declarations 
 : @param tnames a name filter for type definitions 
 : @param gnames a name filter for group definitions
 : @param hnames a name filter for attribute group definitions
 : @param ens a name filter for the namespace of element declarations 
 : @param ans a name filter for the namespace of attribute declarations 
 : @param tns a name filter for the namespace of type definitions 
 : @param gns a name filter for the namespace of group definitions 
 : @param hns a name filter for the namespace of attribute group definitions 
 : @param global only top-level element declarations are considered 
 : @return schema components matching the component type specific name filter 
 :)
declare function cf:findComps($enames as xs:string?,
                              $anames as xs:string?,
                              $tnames as xs:string?,
                              $gnames as xs:string?,
                              $hnames as xs:string?,
                              $ens as xs:string?,
                              $ans as xs:string?,
                              $tns as xs:string?,
                              $gns as xs:string?,
                              $hns as xs:string?,
                              $global as xs:boolean?,                                 
                              $schemas as element(xs:schema)+)
        as element()* {
        
    let $enames := if (not($enames) and $ens) then '*' else $enames 
    let $anames := if (not($anames) and $ans) then '*' else $anames    
    let $tnames := if (not($tnames) and $tns) then '*' else $tnames
    let $gnames := if (not($gnames) and $gns) then '*' else $gnames
    let $hnames := if (not($hnames) and $hns) then '*' else $hnames
    return if (empty(($enames, $anames, $tnames, $gnames, $hnames))) then $schemas/xs:element else

    let $enamesSF := $enames ! sf:compileStringFilter(.)
    let $anamesSF := $anames ! sf:compileStringFilter(.)    
    let $tnamesSF := $tnames ! sf:compileStringFilter(.)
    let $gnamesSF := $gnames ! sf:compileStringFilter(.)
    let $hnamesSF := $hnames ! sf:compileStringFilter(.)
    let $ensSF := $ens ! sf:compileStringFilter(.)
    let $ansSF := $ans ! sf:compileStringFilter(.)    
    let $tnsSF := $tns ! sf:compileStringFilter(.)
    let $gnsSF := $gns ! sf:compileStringFilter(.)
    let $hnsSF := $hns ! sf:compileStringFilter(.)
    return (
    if (not($enamesSF)) then () else 
        let $fschemas := $schemas[not($ensSF) or sf:matchesStringFilter(@targetNamespace, $ensSF)] 
        return 
            $fschemas/(if ($global) then xs:element else .//xs:element)
            [sf:matchesStringFilter(@name, $enamesSF)], 
    if (not($anamesSF)) then () else 
        let $fschemas := $schemas[not($ansSF) or sf:matchesStringFilter(@targetNamespace, $ansSF)] 
        return 
            $fschemas/(if ($global) then xs:attribute else .//xs:attribute)
            [sf:matchesStringFilter(@name, $anamesSF)], 
    if (not($tnamesSF)) then () else
        let $fschemas := $schemas[not($tnsSF) or sf:matchesStringFilter(@targetNamespace, $tnsSF)]
        return 
            $fschemas/(xs:simpleType, xs:complexType)[sf:matchesStringFilter(@name, $tnamesSF)],
    if (not($gnamesSF)) then () else
        let $fschemas := $schemas[not($gnsSF) or sf:matchesStringFilter(@targetNamespace, $gnsSF)]
        return 
            $fschemas/xs:group[sf:matchesStringFilter(@name, $gnamesSF)],
    if (not($hnamesSF)) then () else
        let $fschemas := $schemas[not($hnsSF) or sf:matchesStringFilter(@targetNamespace, $hnsSF)]
        return 
            $fschemas/xs:attributeGroup[sf:matchesStringFilter(@name, $hnamesSF)]
    )
};

(:~
 : Returns a group definition identified by QName.
 :)
declare function cf:findGroup($qname as xs:QName, $schemas as element()*)
        as element(xs:group)? {
    let $comps :=
        $schemas[string(@targetNamespace) = namespace-uri-from-QName($qname)]        
        /xs:group[@name eq local-name-from-QName($qname)]
    return
        if (count($comps) le 1) then $comps else
        let $baseUris := $comps/base-uri(.)
        (:
        let $_LOG :=
            trace($baseUris, '*** WARNING Multiple occurrence of group '||$qname||': ')
        :)
        return $comps[1]
        
};

(:~
 : Returns an attribute group definition identified by QName.
 :)
declare function cf:findAttributeGroup($qname as xs:QName, $schemas as element()*)
        as element(xs:attributeGroup)? {
    let $comps :=
        $schemas[string(@targetNamespace) = namespace-uri-from-QName($qname)]        
        /xs:attributeGroup[@name eq local-name-from-QName($qname)]
    return $comps[1]
};

(:~
 : Returns a global element declaration identified by QName.
 :)
declare function cf:findElement($qname as xs:QName, $schemas as element()*)
        as element(xs:element)? {
    let $comps :=
        $schemas[string(@targetNamespace) = namespace-uri-from-QName($qname)]        
        /xs:element[@name eq local-name-from-QName($qname)]
    return
        if (count($comps) le 1) then $comps else
        let $baseUris := $comps/base-uri(.)
        (:
        let $_LOG :=
            trace($baseUris, '*** WARNING Multiple occurrence of element '||$qname||': ')
        :)
        return $comps[1]
        
};

(:~
 : Returns a global attribute declaration identified by QName.
 :)
declare function cf:findAttribute($qname as xs:QName, $schemas as element()*)
        as element(xs:attribute)? {
    let $comps :=
        $schemas[string(@targetNamespace) = namespace-uri-from-QName($qname)]        
        /xs:attribute[@name eq local-name-from-QName($qname)]
    return $comps[1]
};

(:~
 : Returns a global type definition.
 :)
declare function cf:findType($qname as xs:QName, $schemas as element()*)
        as element()? {
    let $comps :=
        $schemas[string(@targetNamespace) = namespace-uri-from-QName($qname)]        
        /(xs:complexType, xs:simpleType)[@name eq local-name-from-QName($qname)]
    return
        if (count($comps) le 1) then $comps else
        (:
        let $baseUris := $comps/base-uri(.)        
        let $_LOG :=
            trace($baseUris, '*** WARNING Multiple occurrence of type '||$qname||': ')
        return
        :)
        $comps[1]
};

(:~
 : Returns a local type definition identified by type ID.
 :)
declare function cf:findLocalType($typeID as xs:string, $schemas as element()*)
        as element()? {
    let $comps := $schemas//(xs:complexType, xs:simpleType)[@z:typeID eq $typeID]
    let $_DEBUG := if (count($comps) le 1) then () else trace($comps/base-uri(.), '_COMP_BASE_URI: ')
    return $comps[1]
};
