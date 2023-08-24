(:
 : xco-comp-descriptor - functions creating component descriptors
 :)
module namespace eu="http://www.parsqube.de/ns/xco/edesc-util";

import module namespace co="http://www.parsqube.de/ns/xco/constants"
    at "xco-constants.xqm";
import module namespace cu="http://www.parsqube.de/ns/xco/custom"
    at "xco-custom.xqm";
import module namespace dg="http://www.parsqube.de/ns/xco/debug"
    at "xco-debug.xqm";
import module namespace dm="http://www.parsqube.de/ns/xco/domain"
    at "xco-domain.xqm";
import module namespace ln="http://www.parsqube.de/ns/xco/link"
    at "xco-link.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
  at "xco-namespace.xqm";
import module namespace sd="http://www.parsqube.de/ns/xco/simple-type-description"
  at "xco-stype-description.xqm";
import module namespace u="http://www.parsqube.de/ns/xco/util"
    at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Returns a table summarizing a set of simple type descriptors. The table is 
 : designed to support the creation of an HTML table.
 :
 : @param stypes a sequence of simple type descriptors
 :)
declare function eu:stypesTable($stypes as element()*,
                                $domain as element(domain)?,
                                $options as map(xs:string, item()*)?)
        as element() {
    if (empty($stypes)) then () else
    
    let $custom := $options?custom
    let $stypes :=
    <stypes>{
        for $stype in $stypes
        let $typeQName := $stype/@z:name/resolve-QName(., ..)        
        let $typeName := string($typeQName)
        let $typeId := $stype/@z:typeID
        let $typeLabel := $stype/ u:getDescriptorLocalTypeLabel(.)
        let $displayName := 
            if ($typeLabel) then $typeLabel
            else
                cu:customComponentName(
                    $typeName, 'simpleType', 'sub', 'contab', $domain/@id, $custom)
        let $divId := if ($typeName) then 'type.'||$typeName else 'local-type.'||$typeId
        let $tdesc := $stype/@z:typeDesc/string()
        let $isEnum := sd:isTypeDescriptionEnumDesc($tdesc)
        let $tdetail := 
            if (not($isEnum)) then $tdesc
            else 
                for $enum in $stype//z:enumeration
                return
                    <enum value="{$enum/@z:value}" 
                          anno="{$enum//z:documentation/normalize-space(.)}"/>
        let $anno := $stype/z:annotation/z:documentation/normalize-space(.)
        let $linkName := 
            (: Linking to enum dictionary switched off :)
            if (not($isEnum) or true()) then () 
            else if ($typeId) then ln:getLocalEnumTypeLinkRef($domain, $typeId, $options)
            else ln:getTypeLinkRef($domain, $typeQName, $tdesc, $options)
        let $lname := ($typeName ! replace(., '.+:', ''), $typeLabel)[1]            
        let $globalOrLocal := if ($typeId) then 2 else 1                
        order by $globalOrLocal, $lname            
        return
            <stype divId="{$divId}">{
                <name colspan="1" rowspan="1">{
                    $linkName ! attribute linkName {.},
                    $displayName
                }</name>,
                <description colspan="1" rowspan="1">{$tdetail}</description>,
                <anno colspan="1" rowspan="1">{$anno}</anno>
            }</stype>
    }</stypes>
    
    let $_DEBUG := dg:WRITE_FILE($stypes, 'STYPES.xml', 'stypes', $domain/@name, $options)
    return $stypes
};

(:~
 : Returns a table summarizing the contents of a schema component.
 : The table is designed to support the creation of an HTML
 : table.
 :)
declare function eu:contentTable($comp as element(),
                                 $domain as element(domain)?,
                                 $options as map(xs:string, item()*)?)
        as element() {
    let $custom := $options?custom        
    let $compKind := $comp/local-name(.)
    let $type := $comp/@z:type    
    return
        if ($compKind eq 'element' and $type) then 
            eu:contentTableForTypedElement($comp, $domain, $options)
        else
        
    let $typeQName := $type/resolve-QName(., ..)
    let $isTypeBuiltin := boolean(ns:isQNameBuiltin($typeQName))
    let $typeLinkName := $typeQName ! ln:getTypeLinkRef($domain, ., (), $options)
    let $name := $comp/@z:name/string()
    let $lname := $name ! replace(., '.+:', '')
    let $typeId := $comp/@z:typeID/string()
    let $typeLabel := $comp[self::z:complexType]/
                      @z:typeLocator ! concat(., ' (', $typeId, ')')
    let $ident := ($typeId, $lname)[1]

    (: *** Function items :)
    (: Determines the relevant group name :)
    let $fnGroup := function($e) {$e/ancestor::*:group[1]/@z:name/resolve-QName(., ..)}
    (: Each "part" corresponds to a level of type derivation;
       in case of a group, there is only one level corresponding
       to the complete group :)
    let $parts := (
        if ($comp/self::z:group) then $comp
        else
            let $typeComp := 
                if ($comp/self::z:element) then $comp/(z:complexType, z:simpleType)
                else if ($comp/(self::z:complexType, self::z:simpleType)) then $comp
                else $comp
            return                
                if (not($typeComp/z:baseType)) then $typeComp
                else ($typeComp/(z:baseType, z:restriction, z:extension)))
                
    (: Each "table part" is an element describing the content
       of a part.
     :) 
    let $tableParts :=
        (: Last restriction - extensions before it do not contribute elements :)
        let $lastRestrictionPart := $parts[self::z:restriction][last()]
        
        for $part at $pos in $parts
        let $atts := $part/(z:attribute, z:attributeGroup/z:attribute)        
        let $elems := 
            $part[not(. << $lastRestrictionPart)]
            /descendant::z:element[not(ancestor::z:element[. >> $comp])]
        
        let $attRows := <atts>{$atts/eu:contentTable_attRow(., $domain, $options)}</atts>[$atts]
        let $groups :=
            for tumbling window $grouped in $elems
            start $start previous $previous when 
                let $g1 := $previous/$fnGroup(.)
                let $g2 := $start/$fnGroup(.)
                return $g1 ne $g2 or count(($g1, $g2)) eq 1 or not($previous)
            let $gname := $start/$fnGroup(.)
            (: $startedChoices - 
                    for each element an array containing the started choice elems :) 
            let $startedChoices := array{
                for $elem in $grouped 
                let $sc := $elem/eu:getStartedChoices(.)
                return array{$sc}
            }
            let $countStartedChoices :=
                (: Use tail, as choice text line is displayed before the group :)
                count(array:tail($startedChoices)?*[array:size(.) gt 0])            
            return
                <group name="{$gname}">{
                    for $elem at $pos in $grouped
                    return
                        $elem/eu:contentTable_elemRow(
                            ., $pos, count($grouped), $gname, $startedChoices($pos), 
                            $countStartedChoices, $domain, $options)                    
                }</group>
        let $partElemName :=
            if ($compKind eq 'group') then 'groupContent'
            else if ($pos eq count($parts)) then 'typeContent'
            else 'baseTypeContent'
        return
            element {$partElemName} {
                $part/@z:name/attribute name {.},
                attribute isRestriction {'yes'} [$part is $lastRestrictionPart],
                $attRows,
                $groups
            }
    let $baseType := ($tableParts/self::baseTypeContent)[last()]/@name
    let $baseTypeQName := $baseType/resolve-QName(., $comp)
    let $isBaseTypeBuiltin := $baseTypeQName ! ns:isQNameBuiltin(.)
    let $baseTypeLinkName := $baseTypeQName ! ln:getTypeLinkRef($domain, ., (), $options)                
    let $anno := $parts[z:annotation/z:documentation][last()]/
                        z:annotation/z:documentation/normalize-space(.)
    let $table :=
        <content xmlns:z="http://www.parsqube.de/ns/xco/structure"
                 variant="typeContent" kind="{$compKind}">{
            $name ! attribute name {.},
            $typeId ! attribute typeID {.},
            $typeLabel ! attribute typeLabel {.},
            $baseType ! attribute baseName  {.},
            $baseTypeLinkName ! attribute baseLinkName {.},
            <anno>{$anno}</anno>,
            <rows>{
                for $prefix in $comp/in-scope-prefixes(.) return 
                    namespace {$prefix} {namespace-uri-for-prefix($prefix, $comp)},
                $tableParts
            }</rows>
        }</content>
    let $_DEBUG := dg:WRITE_FILE($table, 'CONTENT_TABLE.xml', 
                       'content_table', $ident, $options)
    return $table
};

(:~
 : Write a content table row describing an element.
 :) 
declare function eu:contentTable_elemRow(
                        $elem as element(), 
                        $itemPos as xs:integer, 
                        $groupSize as xs:integer, 
                        $groupQName as xs:QName?,
                        $startedChoices as array(element(z:choice)+)?,
                        $countGroupMembersWithStartedChoices as xs:integer,
                        $domain as element()?,
                        $options as map(xs:string, item()*))
        as element(row) {
    let $fnChoiceBranchNumberPath := function($n) {
         $n/ancestor-or-self::*[parent::z:choice]
         /u:letterNumber(1 + count(eu:precedingSiblingNonAnno(.)))
         => string-join('')
    }
        
    (: Group column :)
    let $groupCol :=
        if (empty($groupQName)) then <group colspan="1" rowspan="1"/>
        else if ($itemPos gt 1) then ()
        else 
            <group colspan="1" 
                   rowspan="{$groupSize + $countGroupMembersWithStartedChoices}" 
                   linkName="{ln:getLinkRef($domain, 'group', $groupQName, $options)}">{
                string($groupQName)
            }</group>
                
    (: Branch column :)
    let $branchCol :=
        $elem/$fnChoiceBranchNumberPath(.)[.] ! <branch>{.}</branch>
    
    (: The name colspan depends on the presence of a group :)
    let $nameColspan := if ($branchCol) then 1 else 2        
    let $type := $elem/@z:type
    let $typeId := $elem/@z:typeID
    let $typeIdDisplay := $typeId ! concat('local-type: ', .)
    let $typeQName := $type/resolve-QName(., ..)
    let $tdesc := $elem/@z:typeDesc
    let $typeCategory := $elem/@z:typeCategory
    let $isTypeSimple := $typeCategory/u:isTypeCategorySimple(.)
    let $isTypeBuiltin := boolean(ns:isQNameBuiltin($typeQName))
    let $typeLinkName := 
        if ($type) then
            ln:getTypeLinkRef($domain, $typeQName, $tdesc[$isTypeSimple], $options)    
        else if ($typeId) then 
            ln:getLocalTypeLinkRef($domain, $typeId, $tdesc[$isTypeSimple], $options)
        else 
            let $_DEBUG := trace($elem/eu:edescItemPath(.), '*** Item without type, path: ')
            return ()
    let $elemLinkName :=
        if (not($elem/@z:reference eq 'yes')) then () 
        else $elem/@z:name ! ln:getLinkRef($domain, 'element', resolve-QName(., ..), $options)
    let $startChoice := (
        array:flatten($startedChoices)/eu:getChoiceSummary(.) => string-join('; ')
        )[string()]
    return
        <row typeCategory="{$typeCategory}">{
            (: The @startChoice attribute will trigger a text line similar to 
               "The element contains one of ..." :)
            $startChoice ! attribute startChoice {.},
            $groupCol,
            $branchCol,
            <name colspan="{$nameColspan}" rowspan="1">{
                $elemLinkName ! attribute linkName {.},
                $elem/@z:name/string()
            }</name>,
            <occ colspan="1" rowspan="1">{$elem/@z:occ/string()}</occ>,
            <type colspan="1" rowspan="1" builtin="{$isTypeBuiltin}">{
                $typeLinkName ! attribute linkName {.},                
                ($type/string(), $typeIdDisplay)
            }</type>,
            <anno colspan="1" rowspan="1">{$elem/z:annotation/z:documentation/normalize-space(.)}</anno>
        }</row>
};

(:~
 : Write a content table row describing an attribute.
 :) 
declare function eu:contentTable_attRow($att,
                                        $domain,
                                        $options as map(xs:string, item()*))
        as element(row) {
    let $nameColspan := 2        
    let $type := $att/@z:type
    let $typeQName := $type/resolve-QName(., ..)
    let $isTypeBuiltin := boolean(ns:isQNameBuiltin($typeQName))
    let $isSimpleType := $att/@z:typeCategory/starts-with(., 's')
    let $typeLinkName := $typeQName 
                         ! ln:getTypeLinkRef($domain, ., $att/@z:typeDesc[$isSimpleType], $options)                
    return
        <row>{
            <group colspan="1" rowspan="1"/>,
            <name colspan="{$nameColspan}" rowspan="1">{'@'||$att/@z:name/string()}</name>,
            <occ colspan="1" rowspan="1">{$att/@z:occ/string()}</occ>,
            <type colspan="1" rowspan="1" builtin="{$isTypeBuiltin}">{
                $typeLinkName ! attribute linkName {.},                
                $type/string()
            }</type>,
            <anno colspan="1" rowspan="1">{$att/z:annotation/z:documentation/normalize-space(.)}</anno>
        }</row>
}; 


(:~
 : Returns a table summarizing the contents of a schema content.
 : The table is designed to support the creation of an HTML
 : table.
 :)
declare function eu:contentTableForTypedElement($comp as element(),
                                                $domain as element(domain)?,
                                                $options as map(xs:string, item()*)?)
        as element() {
    let $compKind := 'element'
    let $custom := $options?custom        
    let $type := $comp/@z:type
    let $typeQName := $type/resolve-QName(., ..)
    let $isTypeBuiltin := boolean(ns:isQNameBuiltin($typeQName))
    let $isTypeSimple := $comp/@z:typeCategory/u:isTypeCategorySimple(.)
    let $typeLinkName := $typeQName 
                         ! ln:getTypeLinkRef($domain, ., $comp/@z:typeDesc[$isTypeSimple], $options)
    let $name := $comp/@z:name/string()
    return
        <content variant="typeName" kind="{$compKind}" name="{$name}">{
            let $compDisplayName := cu:customComponentName(
                $name, $compKind, 'main', 'contab', $domain/@id, $custom)            
            let $typeDisplayName := cu:customComponentName(
                $type, 'complexType', 'sub', 'contab', $domain/@id,  $custom)
            let $anno := $comp/z:annotation/z:documentation/normalize-space(.)
            let $sgroup := $comp/@z:substitutionGroup/string()
            return
                <rows>{
                    <row>{
                        <name colspan="4" rowspan="1">{$compDisplayName}</name>,
                        <type colspan="1" rowspan="1" substitutionGroup="{$sgroup}">{
                            $typeLinkName ! attribute linkName {.},
                            $typeDisplayName
                        }</type>,
                        <anno colspan="1" rowspan="1">{$anno}</anno>
                    }</row>
                }</rows>
        }</content>
};

(:~
 : Returns the immediately enclosing z:choice elements whose first branch starts
 : with element $elem. A choice element is "immediately enclosing" if $elem is
 : not contained by an element contained by the choice.
 :)
declare function eu:getStartedChoices($elem as element())
        as element(z:choice)* {
    let $firstChoiceAnc := $elem/ancestor::z:choice[1]
    where $firstChoiceAnc
    let $firstElemAnc := $elem/ancestor::z:element[1]
    where not($firstElemAnc >> $firstChoiceAnc)
    where
        (: The element and enclosing elements within the enclosing choice branch element
           (e.g. a z:sequence element) must not be preceded by other elements.
         :)
        every $anc in $elem/ancestor-or-self::*[. >> $firstChoiceAnc] satisfies
              $anc/empty(preceding-sibling::*[not(self::z:annotation)])
    let $containingBranchElem := $firstChoiceAnc/ancestor-or-self::*[parent::z:choice][1]              
    return (
        $firstChoiceAnc/eu:getStartedChoices(.)
            [$containingBranchElem/empty(eu:precedingSiblingNonAnno(.))],
        $firstChoiceAnc
    )
};

(:~
 : Returns the preceding siblings except z:annotation elements.
 :)
declare function eu:precedingSiblingNonAnno($elem as element())
        as element()* {
    $elem/(preceding-sibling::* except preceding-sibling::z:annotation)        
};        

(:~
 : Returns the child elements except z:annotation elements.
 :)
declare function eu:childElemsNonAnno($elem as element())
        as element()* {
    $elem/(* except z:annotation)        
};        

(:
 :    F u n c t i o n s    s u m m a r i z i n g    c h o i c e s
 :)

(:~
 : Returns a summary of a choice element. The summary is a ; 
 : concatenated list of up to three items:
 : - elems=...
 :   which branches (a, b, c, ...) correspond to a single element;
 :   examples: elems=a-d, elems=a,d
 : - seqs=...
 :   which branches correspond to a sequence of elements
 :   examples: seqs=a-d, seqs=a,d
 : - contextbranch=...
 :   If the choice corresponds to a branch of a parent choice, the
 :   "path" of  ancestor branches;
 :   examples: contextbranch=b, contextbranch=ba
 : If a contextbranch exists, the branch labels reported in elems=
 : and seqs= are preceded by the contextbranch. Examples:
 : contextbranch=b, elems=ba-bc, seqs=bd  
 : contextbranch=ba, elems=baa-bac, seqs=bad
 :
 : @param choice a choice element from an extended component descriptor
 : @return the choice summary
 :) 
declare function eu:getChoiceSummary($choice as element(z:choice))
        as xs:string {
    let $fnChoiceBranchNumberPath := function($n) {
         let $elemAnc1 := $n/ancestor::z:element[1] return
         $n/ancestor-or-self::*[not(. >> $elemAnc1)][parent::z:choice]
         /u:letterNumber(1 + count(eu:precedingSiblingNonAnno(.)))
         => string-join('')
    }
        
    let $fnPosString := function($positions, $prefix) {
        if (not($positions)) then ()
        else if (contains('a b c d e f g h i j k l m n o p q r s t u v w', 
                 $positions))
        then
            let $seq := tokenize($positions)
            return 
                if (count($seq) eq 1) then $prefix||$seq
                else $prefix||$seq[1]||'-'||$prefix||$seq[last()]
        else tokenize($positions) ! $prefix||. => string-join(',')        
    }

    let $choicePositionPrefix := $choice/$fnChoiceBranchNumberPath(.)
    let $branchKinds :=        
        for $child at $pos in $choice/eu:childElemsNonAnno(.)        
        let $posLetter := u:letterNumber($pos)
        let $branchKind := $child/eu:getChoiceBranchKind(.)
        return $branchKind||'~'||$posLetter
    let $elemBranches := 
        $branchKinds[starts-with(., 'elem')] ! substring-after(., '~')
        => string-join(' ')
    let $sequenceBranches := 
        $branchKinds[starts-with(., 'sequence')] ! substring-after(., '~')
        => string-join(' ')
    let $result := string-join((
        $elemBranches[string()] ! $fnPosString(., $choicePositionPrefix) ! concat('elems=', .),
        $sequenceBranches[string()] ! $fnPosString(., $choicePositionPrefix) ! concat('seqs=', .),
        $choicePositionPrefix[string()] ! concat('contextbranch=', .)
        ), ', ')
    return $result               
};

(:~
 : Returns the kind of a choice branch, which is 'elem' or
 : 'sequence'. A non-recursive call should provide as argument
 : a child element of a z:choice element.
 :) 
declare function eu:getChoiceBranchKind($elem as element())
        as xs:string {
    typeswitch($elem)
    case element(z:element) return 'elem'
    case element(z:sequence) return
        let $children := eu:childElemsNonAnno($elem)
        return
            if (count($children) gt 1) then 'sequence'
            else if ($elem/z:element) then 'elem'
            else $children/eu:getChoiceBranchKind(.)
    case element(z:all) return 'all'
    case element(z:annotation) return ()
    case element(z:choice) | element(z:group) return
        let $childKinds := $elem/eu:childElemsNonAnno(.)/eu:getChoiceBranchKind(.)
        return
            if ($childKinds = 'sequence') then 'sequence'
            else if ($childKinds = 'elem') then 'elem'
            else error()
    default return error()  
};

(:~
 : Returns the simple type definitions of enum types used by an
 : edesc report.
 : 
 : @param report an edesc report
 : @return a sequence of type descriptors
 :)
declare function eu:getEdescReportEnumTypes($report as element())
        as element(z:simpleType)* {
    let $enumTypes1 := $report//z:components/z:simpleType[.//z:enumeration]
    let $enumTypes2 := 
        for $stype in 
            $report//z:components/(* except z:simpleType)
            //z:simpleType[.//z:enumeration][not(ancestor::z:simpleType)]
        let $typeId := $stype/@z:typeID
        group by $typeId
        return $stype[1]
    return ($enumTypes1, $enumTypes2)        
};

(:~
 : Returns the simple type definitions used by an edesc report.
 : 
 : @param report an edesc report
 : @return a sequence of type descriptors
 :)
declare function eu:getEdescReportSimpleTypes($report as element())
        as element(z:simpleType)* {
    let $enumTypes1 := $report//z:components/z:simpleType
    let $enumTypes2 := 
        for $stype in 
            $report//z:components/(* except z:simpleType)
            //z:simpleType[not(ancestor::z:simpleType)]
        let $typeId := $stype/@z:typeID
        group by $typeId
        return $stype[1]
    return ($enumTypes1, $enumTypes2)        
};

(:~
 : Returns a data path of an extended descriptor node representing an element
 : or attribute. The path identifies the containing global component and the
 : element/attribute path leading to the item.
 :)
declare function eu:edescItemPath($item as element())
        as xs:string {
    let $globalComp := 
        $item/ancestor-or-self::*[parent::z:components or position() eq last()][1]
    let $globalCompName := $globalComp/@z:name/concat('name=', .)
    let $globalCompId := $globalComp/@z:typeID/concat('typeID=', .)
    let $globalCompIdent := ($globalCompName, $globalCompId)[1]
    let $globalCompKind := $globalComp/local-name()
    let $withinCompPath := 
        $item/ancestor-or-self::*[self::z:element, self::attribute]
        [. >> $globalComp]/concat(self::z:attribute()/'@', @z:name) 
        => string-join('/')
    return
        string-join((
            $globalCompKind||'['||$globalCompIdent||']',
            $withinCompPath[string()]
        ), '/')
        
};
