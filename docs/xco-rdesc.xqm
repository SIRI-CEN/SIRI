(:
 : xco-resc - functions creating rdesc component descriptors
 :)
module namespace rd="http://www.parsqube.de/ns/xco/rdesc";

import module namespace cd="http://www.parsqube.de/ns/xco/desc"
  at "xco-desc.xqm";
import module namespace cn="http://www.parsqube.de/ns/xco/comp-names"
  at "xco-comp-names.xqm";
import module namespace co="http://www.parsqube.de/ns/xco/constants"
  at "xco-constants.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
  at "xco-namespace.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Returns for each given schema component the component descriptor
 : and the component descriptors of all other schema components on
 : which the given component depends.
 :
 : Input schema components may be global element declarations, type 
 : definitions and group definitions.
 :
 : A component depends on another comonent if it directly or indirectly
 : references it (base type reference, group reference, attribute group
 : reference).
 :
 : The descriptors of components which the given component depends
 : are arranged in a map, using the component kind as keys (group, 
 : attributeGroup, element, attribute, type, localtype).
 :
 : @param comps schema components
 : @return component descriptors of those components, and of those
 :   components on which they depend
 :)
declare function rd:getRequiredCompDescs($comps as element()*,
                                         $nsmap as element(z:nsMap),
                                         $schemas as element(xs:schema)*,
                                         $options as map(xs:string, item()*))
        as map(xs:string, item()*) {
    let $options := map:put($options, 'deepResolve', false())         
    for $comp in $comps
    let $compDescs := rd:getRequiredCompDescsREC($comp, (), $nsmap, $schemas, $options) 
    let $requiredRaw := $compDescs => tail()
    let $required :=
        if (empty($requiredRaw)) then () else
        (: Arrange the required descriptors in a map :)
        let $groups := $requiredRaw/self::z:group
        let $attributeGroups := $requiredRaw/self::z:attributeGroup
        let $elems := $requiredRaw/self::z:element
        let $atts := $requiredRaw/self::z:attribute
        let $types := $requiredRaw/(self::z:simpleType, self::z:complexType)[@z:name]
        let $localTypes := $requiredRaw/(self::z:simpleType, self::z:complexType)[@z:typeID]
        return map:merge((
            map:entry('group', $groups)[$groups],
            map:entry('attributeGroup', $attributeGroups)[$attributeGroups],
            map:entry('element', $elems)[$elems],
            map:entry('attribute', $atts)[$atts],
            map:entry('type', $types)[$types],
            map:entry('localType', $localTypes)[$localTypes]
        ))            
    return
        map{'main': $compDescs => head(), 
            'required': $required}
};

(:~
 : Recursive helper function of `rd:getRequiredCompDescs`.
 :
 : @param comps schema components
 : @param namesAvailable the qualified names of component descriptors already 
 :   collected
 : @param nsmap a map of normalized namespace bindings
 : @param schemas a set of schema elements
 : @param options options controlling the processing
 : @return component descriptors of the schema components, followed
 :   by the component descriptors on which the given components depend
 :)
declare function rd:getRequiredCompDescsREC(
                                         $comps as element()*,
                                         $namesAvailable as map(xs:string, item()*)?,
                                         $nsmap as element(z:nsMap),
                                         $schemas as element(xs:schema)*,
                                         $options as map(xs:string, item()*))
        as element()* {
    let $compDescs := cd:getCompDescs($comps, $nsmap, $options)
    let $newNamesAvailable := cn:mergeCompNames(cn:getCompNames($comps), $namesAvailable)
    let $requiredCompNamesRaw := rd:getRequiredCompNames($compDescs, $options)
    let $requiredCompNames := cn:compNamesExcept($requiredCompNamesRaw, $newNamesAvailable)
    let $requiredCompsMap := cn:resolveCompNames($requiredCompNames, $schemas, true())
    let $requiredComps := $requiredCompsMap?*
    return (
        $compDescs,
        if (empty($requiredComps)) then () else
        rd:getRequiredCompDescsREC($requiredComps, $newNamesAvailable,  $nsmap, $schemas, $options)
        [$requiredComps]
    )
};

(:~
 : Returns the qualified names of components referenced by a set of component
 : descriptors. The component names are returned as a map with component kinds 
 : as keys and a sequence of qualified component names as values.
 :
 : Component kinds used as keys: group, attributeGroup, element, attribute,
 : type, localType.
 :
 : @param compDescs component descriptors
 : @param options options controlling the processing
 : @return a map of qualified component names
 :) 
declare function rd:getRequiredCompNames($compDescs as element()*,
                                         $options as map(xs:string, item()*))
        as map(xs:string, item()*) {
    map:merge(
        let $groupNames := $compDescs//z:group/@z:ref/resolve-QName(., ..)
        let $attributeGroupNames := $compDescs//z:attributeGroup/@z:ref/resolve-QName(., ..)
        let $elemNames := $compDescs//z:element/@z:ref/resolve-QName(., ..)
        let $attNames := $compDescs//z:attribute/@z:ref/resolve-QName(., ..)
        let $typeNames := (
            $compDescs//@z:base/resolve-QName(., ..),
            $compDescs//@z:itemType/resolve-QName(., ..),           
            for $memberTypes in $compDescs//@z:memberTypes return
                tokenize($memberTypes) ! resolve-QName(., $memberTypes/..),
                
            (: Deep resolving (content type names) dependent on $options?deepResolve ... :)
            $compDescs//@z:type[$options?deepResolve]/resolve-QName(., ..))
            
            [not(ns:isQNameBuiltin(.))]            
            => distinct-values()
        let $localTypeNames := $compDescs//@z:typeID
        return (
            map:entry('group', $groupNames)[exists($groupNames)],
            map:entry('attributeGroup', $attributeGroupNames)[exists($attributeGroupNames)],
            map:entry('element', $elemNames)[exists($elemNames)],
            map:entry('attribute', $attNames)[exists($attNames)],
            map:entry('type', $typeNames)[exists($typeNames)],
            map:entry('localType', $localTypeNames)[exists($localTypeNames)]
        )
    )
};
