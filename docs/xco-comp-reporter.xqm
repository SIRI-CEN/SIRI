module namespace cr="http://www.parsqube.de/ns/xco/comp-reporter";

import module namespace rp="http://www.parsqube.de/ns/xco/reporter"
at "xco-reporter.xqm";

import module namespace cf="http://www.parsqube.de/ns/xco/comp-finder"
at "xco-comp-finder.xqm";

import module namespace cd="http://www.parsqube.de/ns/xco/desc"
at "xco-desc.xqm";

import module namespace ed="http://www.parsqube.de/ns/xco/edesc"
at "xco-edesc.xqm";

import module namespace u="http://www.parsqube.de/ns/xco/util"
at "xco-util.xqm";

import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
at "xco-namespace.xqm";

import module namespace co="http://www.parsqube.de/ns/xco/constants"
at "xco-constants.xqm";

import module namespace hl="http://www.parsqube.de/ns/xco/html"
at "xco-html.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

declare function cr:reportComps($reportType as xs:string?,
                                $enames as xs:string?,
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
                                $schemas as element(xs:schema)+,
                                $options as map(xs:string, item()*))
        as item()* {
    let $nsmap := $options?nsmap
    let $comps := cf:findComps(
        $enames, $anames, $tnames, $gnames, $hnames, 
        $ens, $ans, $tns, $gns, $hns, 
        $global, $schemas )
    return
        switch($reportType)
        case 'def' return 
            rp:compDefReport($comps, $nsmap, $schemas, $options)
        case 'edesc' return 
            rp:expandedCompDescsReport($comps, $nsmap, $schemas, $options)
        case 'rdesc' return 
            rp:requiredCompDescsReport($comps, $nsmap, $schemas, $options)
        case 'desc' return 
            rp:compDescsReport($comps, $nsmap, $schemas, $options)
        case 'contab' return 
            rp:contabReport($comps, $nsmap, $schemas, $options)
        default return error(QName((), 'UNKNOWN_REPORT_TYPE'),
            'Unknown report type: '||$reportType)
};
