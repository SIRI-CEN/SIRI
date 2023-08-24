(:
 : xco-required-comp-descriptor - functions creating component descriptors
 :)
module namespace ed="http://www.parsqube.de/ns/xco/required-comp-descriptor";

import module namespace cd="http://www.parsqube.de/ns/xco/comp-descriptor"
  at "xco-comp-descriptor.xqm";
import module namespace cn="http://www.parsqube.de/ns/xco/comp-names"
  at "xco-comp-names.xqm";
import module namespace co="http://www.parsqube.de/ns/xco/constants"
  at "xco-constants.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
  at "xco-namespace.xqm";
import module namespace sd="http://www.parsqube.de/ns/xco/simple-type-description"
  at "xco-stype-description.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Returns for each given schema component the component descriptor
 : and the component descriptors of all other schema components on
 : which it depends.
 :
 : @param comps schema components
 : @return component descriptors
 :)
declare function ed:getRequiredCompDescs($comps as element()*,
                                         $nsmap as element(z:nsMap),
                                         $schemas as element(xs:schema)*,
                                         $options as map(xs:string, item()*))
        as map(xs:string, item()*) {
    let $_DEBUG := trace('GET_REQUIRED_COMP_DESCS called')        
    let $_DEBUG := trace('COMP-NAME='||$comps[1]/@name)
    for $comp in $comps
    let $_DEBUG := $comp/trace('*** Get required components for '||name()||': '||@name)
    let $compDescs := ed:getRequiredCompDescsREC($comp, (), $nsmap, $schemas, $options) 
    let $requiredRaw := $compDescs => tail()
    let $required :=
        if (empty($requiredRaw)) then () else
        
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
        map{'main': $compDescs => head(), 'required': $required}
};

declare function ed:getRequiredCompDescsREC(
                                         $comps as element()*,
                                         $namesAvailable as map(xs:string, item()*)?,
                                         $nsmap as element(z:nsMap),
                                         $schemas as element(xs:schema)*,
                                         $options as map(xs:string, item()*))
        as element()* {
    let $compDescs := cd:getCompDescs($comps, $nsmap, $options)
    let $newNamesAvailable := cn:mergeCompNames(cn:getCompNames($comps), $namesAvailable)
    let $requiredCompNamesRaw := ed:getRequiredCompNames($compDescs, $options)
    let $requiredCompNames := cn:compNamesExcept($requiredCompNamesRaw, $newNamesAvailable)
    let $requiredCompsMap := cn:resolveCompNames($requiredCompNames, $schemas, true())
    let $requiredComps := $requiredCompsMap?*
    return (
        $compDescs,
        if (empty($requiredComps)) then () else
        ed:getRequiredCompDescsREC($requiredComps, $newNamesAvailable,  $nsmap, $schemas, $options)
        [$requiredComps]
    )
};

declare function ed:getRequiredCompNames($compDescs as element()*,
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
                tokenize($memberTypes) ! resolve-QName(., $memberTypes/..)
            )[not(namespace-uri-from-QName(.) eq $co:URI_XSD)] 
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
