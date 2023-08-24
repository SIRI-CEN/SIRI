(:
 : xco-comp-descriptor - functions creating component descriptors
 :)
module namespace cd="http://www.parsqube.de/ns/xco/desc";

import module namespace cf="http://www.parsqube.de/ns/xco/comp-finder"
at "xco-comp-finder.xqm";

import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
at "xco-namespace.xqm";

import module namespace cn="http://www.parsqube.de/ns/xco/comp-names"
at "xco-comp-names.xqm";

import module namespace u="http://www.parsqube.de/ns/xco/util"
at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Describe me
 :
 : @param comps schema components
 : @return component descriptors
 :)
declare function cd:getCompDescs($comps as element()*,
                                 $nsmap as element(z:nsMap),
                                 $options as map(xs:string, item()*))
        as element()* {
    for $comp in $comps[@name or @z:typeID]
    let $desc :=
        typeswitch($comp)
        case element(xs:group) return cd:getGroupCompDescs($comp, $nsmap, $options)
        case element(xs:attributeGroup) return cd:getAttributeGroupCompDescs($comp, $nsmap, $options)
        case element(xs:element) return cd:getElementCompDescs($comp, $nsmap, $options)
        case element(xs:attribute) return cd:getAttributeCompDescs($comp, $nsmap, $options)
        case element(xs:simpleType) return cd:getSimpleTypeCompDescs($comp, $nsmap, $options)
        case element(xs:complexType) return cd:getComplexTypeCompDescs($comp, $nsmap, $options)
        default return error()
    return $desc/ns:addNamespaceContext(., $nsmap, map{'baseUri': $comp/base-uri(.)})        
};

(:~
 : Maps group definitions to component descriptors.
 :
 : @param comps group definitions
 : @param nsmap a map describing standardized namespace bindings 
 : @return group component descriptors
 :)
declare function cd:getGroupCompDescs($comps as element(xs:group)*,
                                      $nsmap as element(z:nsMap),
                                      $options as map(xs:string, item()*)?)
        as element() {
    $comps/cd:getGroupCompDescsREC(., $nsmap, $options)
};

(:~
 : Recursive helper function of `getGroupCompDescs`.
 :)
declare function cd:getGroupCompDescsREC($n as node(),
                                         $nsmap as element(z:nsMap),
                                         $options as map(xs:string, item()*)?)
        as node()* {
    typeswitch($n)
    case element(xs:all) | element(xs:choice) | element(xs:sequence) return
        $n/cd:copyElem(., cd:getGroupCompDescsREC#3, $nsmap, $options)
    case element(xs:annotation) | element(xs:appinfo) | element(xs:documentation) return
        $n/cd:copyElem(., cd:getGroupCompDescsREC#3, $nsmap, $options)    
    case element(xs:element) return
        $n/cd:copyElementElem(., cd:getGroupCompDescsREC#3, $nsmap, $options)
    case element(xs:group) return
        $n/cd:copyElem(., cd:getGroupCompDescsREC#3, $nsmap, $options)
    case element() return
        $n/cd:copyOtherElem(., cd:getGroupCompDescsREC#3, $nsmap, $options) 
        
    (: attributes :)    
    case attribute(base) return $n/cd:writeTypeAtt(., $nsmap, $options)
    case attribute(default) return $n/cd:copyAtt(., $options)
    case attribute(maxOccurs) return $n/cd:copyAtt(., $options)
    case attribute(minOccurs) return $n/cd:copyAtt(., $options)
    case attribute(name) return $n/cd:copyNameAtt(., $nsmap, $options)
    case attribute(ref) return $n/cd:copyQNameAtt(., $nsmap, $options)
    case attribute(type) return $n/cd:writeTypeAtt(., $nsmap, $options)
    case attribute(z:typeID) return $n/cd:writeTypeIdAtt(., $nsmap, $options)
    case attribute() return $n/cd:copyOtherAtt(., $options)
    case text() | comment() return $n
    default return $n
};

(:~
 : Maps attribute group definitions to component descriptors.
 :
 : @param comps attribute group definitions)
 : @param nsmap a map describing standardized namespace bindings 
 : @return group component descriptors
 :)
declare function cd:getAttributeGroupCompDescs($comps as element(xs:attributeGroup)*,
                                               $nsmap as element(z:nsMap),
                                               $options as map(xs:string, item()*)?)
        as element() {
    $comps/cd:getAttributeGroupCompDescsREC(., $nsmap, $options)
};

(:~
 : Recursive helper function of `getAttributeGroupCompDescs`.
 :)
declare function cd:getAttributeGroupCompDescsREC($n as node(),
                                                  $nsmap as element(z:nsMap),
                                                  $options as map(xs:string, item()*)?)
        as node()* {
    typeswitch($n)
    case element(xs:annotation) | element(xs:appinfo) | element(xs:documentation) return
        $n/cd:copyElem(., cd:getAttributeGroupCompDescsREC#3, $nsmap, $options)
    case element(xs:attribute) return
        $n/cd:copyAttributeElem(., cd:getAttributeGroupCompDescsREC#3, $nsmap, $options)    
    case element(xs:attributeGroup) return
        $n/cd:copyElem(., cd:getAttributeGroupCompDescsREC#3, $nsmap, $options)
    case element() return
        $n/cd:copyOtherElem(., cd:getAttributeGroupCompDescsREC#3, $nsmap, $options)
        
    (: attributes :)
    case attribute(default) return $n/cd:copyAtt(., $options)    
    case attribute(name) return $n/cd:copyNameAtt(., $nsmap, $options)
    case attribute(ref) return $n/cd:copyQNameAtt(., $nsmap, $options)    
    case attribute(type) return $n/cd:writeTypeAtt(., $nsmap, $options)
    case attribute(use) return $n/cd:copyAtt(., $options)
    case attribute(z:typeID) return $n/cd:writeTypeIdAtt(., $nsmap, $options)    
    case attribute() return $n/cd:copyOtherAtt(., $options)
    case text() | comment() return $n
    default return $n
};

(:~
 : Maps element declarations to component descriptors.
 :
 : @param comps element declarations
 : @param nsmap a map describing standardized namespace bindings 
 : @return group component descriptors
 :)
declare function cd:getElementCompDescs($comps as element(xs:element)*,
                                        $nsmap as element(z:nsMap),
                                        $options as map(xs:string, item()*)?)
        as element() {
    $comps/cd:getElementCompDescsREC(., $nsmap, $options)
};

(:~
 : Recursive helper function of `getElementCompDescs`.
 :)
declare function cd:getElementCompDescsREC($n as node(),
                                           $nsmap as element(z:nsMap),
                                           $options as map(xs:string, item()*)?)
        as node()* {
    typeswitch($n)
    case element(xs:annotation) | element(xs:appinfo) | element(xs:documentation) return
        $n/cd:copyElem(., cd:getElementCompDescsREC#3, $nsmap, $options)
    case element(xs:element) return
        $n/cd:copyElementElem(., cd:getElementCompDescsREC#3, $nsmap, $options)    
    case element(xs:field) | 
         element(xs:key) |
         element(xs:keyref) |         
         element(xs:selector) | 
         element(xs:unique) return $n/cd:copyElem(., cd:getElementCompDescsREC#3, $nsmap, $options)
    case element() return
        $n/cd:copyOtherElem(., cd:getAttributeGroupCompDescsREC#3, $nsmap, $options)
        
    (: attributes :)
    case attribute(abstract) return $n/cd:copyAtt(., $options)    
    case attribute(default) return $n/cd:copyAtt(., $options) 
    case attribute(fixed) return $n/cd:copyAtt(., $options)    
    case attribute(id) return $n/cd:copyAtt(., $options)
    case attribute(minOccurs) | 
         attribute(maxOccurs) return $n/cd:copyAtt(., $options)    
    case attribute(name) return $n/cd:copyNameAtt(., $nsmap, $options)
    case attribute(ref) return $n/cd:copyQNameAtt(., $nsmap, $options)
    case attribute(refer) return $n/cd:copyQNameAtt(., $nsmap, $options)
    case attribute(substitutionGroup) return $n/cd:copyQNameAtt(., $nsmap, $options)    
    case attribute(type) return $n/cd:writeTypeAtt(., $nsmap, $options)
    case attribute(xpath) return $n/cd:copyAtt(., $options)
    case attribute(z:typeID) return $n/cd:writeTypeIdAtt(., $nsmap, $options)
    case attribute() return $n/cd:copyOtherAtt(., $options)    
    case text() | comment() return $n
    default return $n 
};

(:~
 : Maps attribute declarations to component descriptors.
 :
 : @param comps attribute declarations
 : @param nsmap a map describing standardized namespace bindings 
 : @return group component descriptors
 :)
declare function cd:getAttributeCompDescs($comps as element(xs:attribute)*,
                                          $nsmap as element(z:nsMap),
                                          $options as map(xs:string, item()*)?)
        as element() {
    $comps/cd:getAttributeCompDescsREC(., $nsmap, $options)
};

(:~
 : Recursive helper function of `getAttributeCompDescs`.
 :)
declare function cd:getAttributeCompDescsREC($n as node(),
                                             $nsmap as element(z:nsMap),
                                             $options as map(xs:string, item()*)?)
        as node()* {
    typeswitch($n)
    case element(xs:annotation) | element(xs:appinfo) | element(xs:documentation) return
        $n/cd:copyElem(., cd:getAttributeCompDescsREC#3, $nsmap, $options)
    case element(xs:attribute) return
        $n/cd:copyAttributeElem(., cd:getAttributeCompDescsREC#3, $nsmap, $options)    
    case element() return
        $n/cd:copyOtherElem(., cd:getAttributeCompDescsREC#3, $nsmap, $options)
        
    (: attributes :)
    case attribute(default) return $n/cd:copyAtt(., $options) 
    case attribute(fixed) return $n/cd:copyAtt(., $options)
    case attribute(name) return $n/cd:copyNameAtt(., $nsmap, $options)
    case attribute(ref) return $n/cd:copyQNameAtt(., $nsmap, $options)
    case attribute(type) return $n/cd:writeTypeAtt(., $nsmap, $options)    
    case attribute(use) return $n/cd:copyAtt(., $options)
    case attribute(z:typeID) return $n/cd:writeTypeIdAtt(., $nsmap, $options)
    case attribute() return $n/cd:copyOtherAtt(., $options)    
    case text() | comment() return $n
    default return $n 
};

(:~
 : Maps schema complex type definitions to component descriptors.
 :
 : @param comps complex type definitions
 : @param nsmap a map describing standardized namespace bindings 
 : @return group component descriptors
 :)
declare function cd:getComplexTypeCompDescs(
                    $comps as element(xs:complexType)*,
                    $nsmap as element(z:nsMap),
                    $options as map(xs:string, item()*)?)
        as element(z:complexType) {
    $comps/cd:getComplexTypeCompDescsREC(., $nsmap, $options)
};

(:~
 : Recursive helper function of function `getComplexTypeCompDescs`.
 :)
declare function cd:getComplexTypeCompDescsREC(
                    $n as node(),
                    $nsmap as element(z:nsMap),
                    $options as map(xs:string, item()*)?)
        as node()* {
    typeswitch($n)
    case element(xs:all) | element(xs:choice) | element(xs:sequence) return
        $n/cd:copyElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:annotation) | element(xs:appinfo) | element(xs:documentation) return
        $n/cd:copyElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:attribute) return
        $n/cd:copyAttributeElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)        
    case element(xs:attributeGroup) return
        $n/cd:copyElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:complexContent) | element(xs:simpleContent) return
        $n/cd:copyElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:complexType) return 
        $n/cd:copyTypeElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)
    case element(xs:element) return
        $n/cd:copyElementElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)
    case element(xs:extension) | element(xs:restriction) return
        $n/cd:copyElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:group) return
        $n/cd:copyElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:any) return
        $n/cd:copyElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    
    case element() return
        $n/cd:copyOtherElem(., cd:getComplexTypeCompDescsREC#3, $nsmap, $options)    

    (: attributes :)
    case attribute(abstract) return $n/cd:copyAtt(., $options)
    case attribute(base) return $n/cd:writeTypeAtt(., $nsmap, $options)
    case attribute(default) return $n/cd:copyAtt(., $options)
    case attribute(fixed) return $n/cd:copyAtt(., $options)    
    case attribute(maxOccurs) return $n/cd:copyAtt(., $options)
    case attribute(minOccurs) return $n/cd:copyAtt(., $options)         
    case attribute(name) return $n/cd:copyNameAtt(., $nsmap, $options)
    case attribute(namespace)  return $n/cd:copyAtt(., $options)
    case attribute(processContents)  return $n/cd:copyAtt(., $options)
    case attribute(ref) return $n/cd:copyQNameAtt(., $nsmap, $options)    
    case attribute(type) return $n/cd:writeTypeAtt(., $nsmap, $options) 
    case attribute(use) return $n/cd:copyAtt(., $options)
    case attribute(xml:lang) return $n/cd:copyAtt(., $options)    
    case attribute(z:typeID) return $n/cd:writeTypeIdAtt(., $nsmap, $options)       
    case attribute() return $n/cd:copyOtherAtt(., $options)
    case text() | comment() return $n    
    default return $n
};

(:~
 : Maps simple type definitions to component descriptors.
 :
 : @param simple type definitions
 : @param nsmap a map describing standardized namespace bindings 
 : @return group component descriptors
 :)
declare function cd:getSimpleTypeCompDescs($comps as element(xs:simpleType)*,
                                           $nsmap as element(z:nsMap),
                                           $options as map(xs:string, item()*)?)
        as element() {
    $comps/cd:getSimpleTypeCompDescsREC(., $nsmap, $options)
};

(:~
 : Recursive helper function of function `getSimpleTypeCompDescs`.
 :)
declare function cd:getSimpleTypeCompDescsREC(
                    $n as node(),
                    $nsmap as element(z:nsMap),
                    $options as map(xs:string, item()*)?)
        as node()* {
    typeswitch($n)
    case element(xs:annotation) | element(xs:appinfo) | element(xs:documentation) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:enumeration) | element(xs:pattern) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:extension) | element(xs:restriction) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:list) | element(xs:union) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:maxExclusive) | element(xs:maxInclusive) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:minExclusive) | element(xs:minInclusive) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:maxLength) | element(xs:minLength) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element(xs:simpleType) return 
        $n/cd:copyTypeElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)
    case element(xs:any) return
        $n/cd:copyElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    
    case element() return
        $n/cd:copyOtherElem(., cd:getSimpleTypeCompDescsREC#3, $nsmap, $options)    

    (: attributes :)
    case attribute(base) return cd:writeTypeAtt($n, $nsmap, $options)
    case attribute(final) return $n/cd:copyAtt(., $options)
    case attribute(fixed) return $n/cd:copyAtt(., $options)
    case attribute(itemType) return $n/cd:copyQNameAtt(., $nsmap, $options)
    case attribute(memberTypes) return $n/cd:copyQNamesAtt(., $nsmap, $options)    
    case attribute(name) return cd:copyNameAtt($n, $nsmap, $options)
    case attribute(processContents)  return $n/cd:copyAtt(., $options)
    case attribute(value) return $n/cd:copyAtt(., $options)
    case attribute(xml:lang) return $n/cd:copyAtt(., $options)    
    case attribute(z:typeID) return $n/cd:writeTypeIdAtt(., $nsmap, $options)    
    case attribute() return $n/cd:copyOtherAtt(., $options)
    case text() | comment() return $n    
    default return $n
};

(:
 :    U t i l i t i e s
 :    =================
 :)
 
 declare function cd:copyElem($elem as element(), 
                              $fnRec as function(*),
                              $nsmap as element(z:nsMap),
                              $options as map(xs:string, item()*)?)
        as element() {
    element {'z:'||local-name($elem)} {
        $elem/@* ! $fnRec(., $nsmap, $options),
        $elem/(self::xs:group[@ref], self::xs:sequence, self::xs:choice)/cd:writeOccAtt(.),
        $elem/node() ! $fnRec(., $nsmap, $options)
    }
}; 

declare function cd:copyElementElem($elem as element(),
                                    $fnRec as function(*),
                                    $nsmap as element(z:nsMap),
                                    $options as map(xs:string, item()*)?)
        as element(z:element) {
    $elem/element {'z:'||local-name(.)} {
        @* ! $fnRec(., $nsmap, $options),
        $elem[not(parent::xs:schema)]/cd:writeOccAtt(.),
        (xs:simpleType, xs:complexType)/@z:typeID ! $fnRec(., $nsmap, $options), 
        (node() except (xs:simpleType, xs:complexType)) ! $fnRec(., $nsmap, $options)
    }
};

declare function cd:copyAttributeElem($elem as element(),
                                      $fnRec as function(*),
                                      $nsmap as element(z:nsMap),
                                      $options as map(xs:string, item()*)?)
        as element(z:attribute) {
    $elem/element {'z:'||local-name(.)} {
        @* ! $fnRec(., $nsmap, $options),
        $elem[not(parent::xs:schema)]/cd:writeOccAtt(.),
        xs:simpleType/@z:typeID ! $fnRec(., $nsmap, $options), 
        (node() except xs:simpleType) ! $fnRec(., $nsmap, $options)
    }
};

declare function cd:copyTypeElem($type as element(),
                                 $fnRec as function(*),
                                 $nsmap as element(z:nsMap),
                                 $options as map(xs:string, item()*)?)
        as element() {
    $type/element {'z:'||local-name(.)} {
        @* ! $fnRec(., $nsmap, $options),
        attribute z:typeCategory {u:typeCategory($type)},
        node() ! $fnRec(., $nsmap, $options)
    }
};

declare function cd:copyOtherElem($elem as element(),
                                  $fnRec as function(*),
                                  $nsmap as element(z:nsMap),
                                  $options as map(xs:string, item()*)?)
        as element() {
    if ($elem/ancestor::xs:documentation) then
        $elem/cd:copyElem(., $fnRec, $nsmap, $options)
    else error(QName((), 'UNEXPECTED_ELEMENT'), 
        concat('Unexpected element, local name=', $elem/local-name(.)))
};

declare function cd:copyOtherAtt($att as attribute(),
                                 $options as map(xs:string, item()*)?)
        as attribute() {
    if ($att/ancestor::xs:documentation) then
        $att/cd:copyAtt(., $options)
    else error(QName((), 'UNEXPECTED_ATTRIBUTE'), 
        concat('Unexpected attribute,local name=', $att/local-name(.)))
};

declare function cd:copyAtt($att as attribute(), 
                            $options as map(xs:string, item()*)?)
        as attribute() {
    $att/attribute {'z:'||local-name(.)} {.}     
};

declare function cd:copyNameAtt($name as attribute(name),
                                $nsmap as element(z:nsMap),
                                $options as map(xs:string, item()*)?)
        as attribute() {
    if ($name/parent::xs:attribute[not(parent::xs:schema)]) then 
        attribute z:name {$name} else
    
    let $qname := $name/QName(ancestor::xs:schema/@targetNamespace, .)
    let $qnameNorm := ns:normalizeQName($qname, $nsmap)
    return attribute z:name {$qnameNorm}
}; 

declare function cd:copyQNameAtt($att as attribute(),
                                 $nsmap as element(z:nsMap),
                                 $options as map(xs:string, item()*)?)
        as attribute() {
    let $qname := $att/resolve-QName(., ..)
    let $qnameNorm := ns:normalizeQName($qname, $nsmap)
    return $att/attribute {'z:'||local-name(.)} {$qnameNorm}     
}; 

declare function cd:copyQNameAtt_noDefaultNamespace(
                                 $att as attribute(),
                                 $nsmap as element(z:nsMap),
                                 $options as map(xs:string, item()*)?)
        as attribute() {
    let $qname := 
        if (not(contains($att, ':'))) then QName((), $att)
        else $att/resolve-QName(., ..)
    let $qnameNorm := ns:normalizeQName($qname, $nsmap)
    return $att/attribute {'z:'||local-name(.)} {$qnameNorm}     
}; 

declare function cd:copyQNamesAtt($att as attribute(),
                                  $nsmap as element(z:nsMap),
                                  $options as map(xs:string, item()*)?)
        as attribute() {
    let $qnamesNorm :=
        for $name in tokenize($att)        
        let $qname := resolve-QName($name, $att/..)
        return ns:normalizeQName($qname, $nsmap)
    return $att/attribute {'z:'||local-name(.)} {$qnamesNorm}     
}; 

declare function cd:writeTypeAtt($att as attribute(),
                                 $nsmap as element(z:nsMap),
                                 $options as map(xs:string, item()*)?)
        as attribute()+ {
    let $schemas := $options?schemas?*        
    let $qnameNorm := 
        resolve-QName($att, $att/..) ! ns:normalizeQName(., $nsmap)
    let $typeCategory := $qnameNorm ! u:typeCategory(., $schemas)
    return (
        $att/attribute {'z:'||local-name(.)} {$qnameNorm},
        $att/attribute {'z:'||local-name(.)||'Category'} {$typeCategory}
    )
}; 

declare function cd:writeTypeIdAtt($att as attribute(z:typeID),
                                   $nsmap as element(z:nsMap),
                                   $options as map(xs:string, item()*)?)
        as attribute()+ {
    $att,
    u:getLocalTypeLocator($att/.., $nsmap, $options) ! attribute z:typeLocator {.}
}; 

declare function cd:writeOccAtt($comp as element())
        as attribute(z:occ) {
    if ($comp/self::attribute()) then 
        if ($comp/@use eq 'required') then '1:1' else '0:1'
    else
    
    let $minOccurs := ($comp/@minOccurs, '1')[1]
    let $maxOccurs := ($comp/@maxOccurs, '1')[1] ! replace(., 'unbounded', '*')
    let $occ := $minOccurs||':'||$maxOccurs
    return attribute z:occ {$occ}
};  

(:~
 : Maps an annotation element to an annotation descriptor.
 :)
declare function cd:annotationDescriptor($anno as element(xs:annotation)?)
        as element(z:annotation)? {
    if (not($anno)) then () else
    <z:annotation>{
        $anno/*/element {'z:'||local-name(.)} {node()}
    }</z:annotation>
};