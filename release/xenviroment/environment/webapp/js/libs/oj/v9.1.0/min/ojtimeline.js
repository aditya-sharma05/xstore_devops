/**
 * @license
 * Copyright (c) 2014, 2020, Oracle and/or its affiliates.
 * Licensed under The Universal Permissive License (UPL), Version 1.0
 * as shown at https://oss.oracle.com/licenses/upl/
 * @ignore
 */
define(["ojs/ojcore","jquery","ojs/ojcomponentcore","ojs/ojtime-base","ojs/internal-deps/dvt/DvtTimeline","ojs/ojattributegrouphandler","ojs/ojkeyset","ojs/ojconverter-datetime"],function(e,t,o,r,i,n,l,s){"use strict";var a={properties:{animationOnDataChange:{type:"string",enumValues:["auto","none"],value:"none"},animationOnDisplay:{type:"string",enumValues:["auto","none"],value:"none"},data:{type:"object"},end:{type:"string",value:""},majorAxis:{type:"object",properties:{converter:{type:"object",properties:{default:{type:"object"},seconds:{type:"object"},minutes:{type:"object"},hours:{type:"object"},days:{type:"object"},weeks:{type:"object"},months:{type:"object"},quarters:{type:"object"},years:{type:"object"}}},scale:{type:"string",enumValues:["days","hours","minutes","months","quarters","seconds","weeks","years"]},svgStyle:{type:"object",value:{}}}},minorAxis:{type:"object",properties:{converter:{type:"object",properties:{default:{type:"object"},seconds:{type:"object"},minutes:{type:"object"},hours:{type:"object"},days:{type:"object"},weeks:{type:"object"},months:{type:"object"},quarters:{type:"object"},years:{type:"object"}}},scale:{type:"string",enumValues:["days","hours","minutes","months","quarters","seconds","weeks","years"]},svgStyle:{type:"object",value:{}},zoomOrder:{type:"Array<string>"}}},orientation:{type:"string",enumValues:["horizontal","vertical"],value:"horizontal"},overview:{type:"object",properties:{rendered:{type:"string",enumValues:["off","on"],value:"off"},svgStyle:{type:"object",value:{}}}},referenceObjects:{type:"Array<Object>",value:[]},selection:{type:"Array<any>",writeback:!0,value:[]},selectionMode:{type:"string",enumValues:["multiple","none","single"],value:"none"},series:{type:"Array<Object>|Promise"},start:{type:"string",value:""},styleDefaults:{type:"object",properties:{animationDuration:{type:"number"},borderColor:{type:"string"},item:{type:"object",value:{},properties:{backgroundColor:{type:"string"},borderColor:{type:"string"},descriptionStyle:{type:"object"},hoverBackgroundColor:{type:"string"},hoverBorderColor:{type:"string"},selectedBackgroundColor:{type:"string"},selectedBorderColor:{type:"string"},titleStyle:{type:"object"}}},majorAxis:{type:"object",value:{},properties:{labelStyle:{type:"object"},separatorColor:{type:"string"}}},minorAxis:{type:"object",value:{},properties:{backgroundColor:{type:"string"},borderColor:{type:"string"},labelStyle:{type:"object"},separatorColor:{type:"string"}}},overview:{type:"object",properties:{backgroundColor:{type:"string"},labelStyle:{type:"object"},window:{type:"object",value:{},properties:{backgroundColor:{type:"string"},borderColor:{type:"string"}}}}},referenceObject:{type:"object",value:{},properties:{color:{type:"string"}}},series:{type:"object",value:{},properties:{backgroundColor:{type:"string"},colors:{type:"Array<string>"},emptyTextStyle:{type:"object"},labelStyle:{type:"object"}}}}},tooltip:{type:"object",value:{renderer:null},properties:{renderer:{type:"function"}}},trackResize:{type:"string",enumValues:["off","on"],value:"on"},translations:{type:"object",value:{},properties:{accessibleItemDesc:{type:"string"},accessibleItemEnd:{type:"string"},accessibleItemStart:{type:"string"},accessibleItemTitle:{type:"string"},componentName:{type:"string"},labelAndValue:{type:"string"},labelClearSelection:{type:"string"},labelCountWithTotal:{type:"string"},labelDataVisualization:{type:"string"},labelDate:{type:"string"},labelDescription:{type:"string"},labelEnd:{type:"string"},labelInvalidData:{type:"string"},labelNoData:{type:"string"},labelSeries:{type:"string"},labelStart:{type:"string"},labelTitle:{type:"string"},stateCollapsed:{type:"string"},stateDrillable:{type:"string"},stateExpanded:{type:"string"},stateHidden:{type:"string"},stateIsolated:{type:"string"},stateMaximized:{type:"string"},stateMinimized:{type:"string"},stateSelected:{type:"string"},stateUnselected:{type:"string"},stateVisible:{type:"string"},tooltipZoomIn:{type:"string"},tooltipZoomOut:{type:"string"}}},valueFormats:{type:"object",properties:{date:{type:"object",properties:{converter:{type:"object"},tooltipDisplay:{type:"string",enumValues:["auto","off"],value:"auto"},tooltipLabel:{type:"string"}}},description:{type:"object",properties:{tooltipDisplay:{type:"string",enumValues:["auto","off"],value:"off"},tooltipLabel:{type:"string"}}},end:{type:"object",properties:{converter:{type:"object"},tooltipDisplay:{type:"string",enumValues:["auto","off"],value:"auto"},tooltipLabel:{type:"string"}}},series:{type:"object",properties:{tooltipDisplay:{type:"string",enumValues:["auto","off"],value:"off"},tooltipLabel:{type:"string"}}},start:{type:"object",properties:{converter:{type:"object"},tooltipDisplay:{type:"string",enumValues:["auto","off"],value:"auto"},tooltipLabel:{type:"string"}}},title:{type:"object",properties:{tooltipDisplay:{type:"string",enumValues:["auto","off"],value:"off"},tooltipLabel:{type:"string"}}}}},viewportEnd:{type:"string",value:""},viewportStart:{type:"string",value:""}},methods:{getContextByNode:{},refresh:{},setProperty:{},getProperty:{},setProperties:{},getNodeBySubId:{},getSubIdByNode:{}},events:{ojViewportChange:{}},extension:{}},p={properties:{description:{type:"string",value:""},durationFillColor:{type:"string"},end:{type:"string",value:""},label:{type:"string",value:""},seriesId:{type:"string"},shortDesc:{type:"string"},start:{type:"string",value:""},svgStyle:{type:"object"},thumbnail:{type:"string",value:""}},extension:{}},y={properties:{emptyText:{type:"string"},itemLayout:{type:"string",enumValues:["auto","bottomToTop","topToBottom"],value:"auto"},label:{type:"string",value:""},svgStyle:{type:"object",value:{}}},extension:{}};e.__registerWidget("oj.ojTimeline",t.oj.dvtTimeComponent,{widgetEventPrefix:"oj",options:{animationOnDataChange:"none",animationOnDisplay:"none",data:null,end:"",minorAxis:{converter:{default:null,seconds:new s.IntlDateTimeConverter({hour:"numeric",minute:"2-digit",second:"2-digit"}),minutes:new s.IntlDateTimeConverter({hour:"numeric",minute:"2-digit"}),hours:new s.IntlDateTimeConverter({hour:"numeric"}),days:new s.IntlDateTimeConverter({month:"numeric",day:"2-digit"}),weeks:new s.IntlDateTimeConverter({month:"numeric",day:"2-digit"}),months:new s.IntlDateTimeConverter({month:"long"}),quarters:new s.IntlDateTimeConverter({month:"long"}),years:new s.IntlDateTimeConverter({year:"numeric"})},scale:null,svgStyle:{},zoomOrder:null},majorAxis:{converter:{default:null,seconds:new s.IntlDateTimeConverter({hour:"numeric",minute:"2-digit",second:"2-digit"}),minutes:new s.IntlDateTimeConverter({hour:"numeric",minute:"2-digit"}),hours:new s.IntlDateTimeConverter({hour:"numeric"}),days:new s.IntlDateTimeConverter({month:"numeric",day:"2-digit"}),weeks:new s.IntlDateTimeConverter({month:"numeric",day:"2-digit"}),months:new s.IntlDateTimeConverter({month:"long"}),quarters:new s.IntlDateTimeConverter({month:"long"}),years:new s.IntlDateTimeConverter({year:"numeric"})},scale:null,svgStyle:{}},orientation:"horizontal",overview:{rendered:"off",svgStyle:{}},referenceObjects:[],selection:[],selectionMode:"none",series:null,start:"",styleDefaults:{animationDuration:void 0,borderColor:void 0,item:{backgroundColor:void 0,borderColor:void 0,descriptionStyle:void 0,hoverBackgroundColor:void 0,hoverBorderColor:void 0,selectedBackgroundColor:void 0,selectedBorderColor:void 0,titleStyle:void 0},minorAxis:{backgroundColor:void 0,borderColor:void 0,labelStyle:void 0,separatorColor:void 0},majorAxis:{labelStyle:void 0,separatorColor:void 0},overview:{backgroundColor:void 0,labelStyle:void 0,window:{backgroundColor:void 0,borderColor:void 0}},referenceObject:{color:void 0},series:{backgroundColor:void 0,colors:["#237bb1","#68c182","#fad55c","#ed6647","#8561c8","#6ddbdb","#ffb54d","#e371b2","#47bdef","#a2bf39","#a75dba","#f7f37b"],emptyTextStyle:void 0,labelStyle:void 0}},tooltip:{renderer:null},valueFormats:{series:{tooltipLabel:void 0,tooltipDisplay:"off"},start:{converter:null,tooltipLabel:void 0,tooltipDisplay:"auto"},end:{converter:null,tooltipLabel:void 0,tooltipDisplay:"auto"},date:{converter:null,tooltipLabel:void 0,tooltipDisplay:"auto"},title:{tooltipLabel:void 0,tooltipDisplay:"off"},description:{tooltipLabel:void 0,tooltipDisplay:"off"}},viewportEnd:"",viewportStart:"",viewportChange:null},_CreateDvtComponent:function(e,t,o){return i.Timeline.newInstance(e,t,o)},_ConvertLocatorToSubId:function(e){var t=e.subId;return"oj-timeline-item"===t?t="timelineItem["+e.seriesIndex+"]["+e.itemIndex+"]":"oj-timeline-tooltip"===t&&(t="tooltip"),t},_ConvertSubIdToLocator:function(e){var t={};if(0===e.indexOf("timelineItem")){var o=this._GetIndexPath(e);t.subId="oj-timeline-item",t.seriesIndex=o[0],t.itemIndex=o[1]}else"tooltip"===e&&(t.subId="oj-timeline-tooltip");return t},_ProcessStyles:function(){if(this.options.styleDefaults||(this.options.styleDefaults={}),this.options.styleDefaults.series||(this.options.styleDefaults.series={}),!this.options.styleDefaults.series.colors){var e=new n.ColorAttributeGroupHandler;this.options.styleDefaults.series.colors=e.getValueRamp()}this._super()},_GetComponentStyleClasses:function(){var e=this._super();return e.push("oj-timeline"),e},_GetChildStyleClasses:function(){var e=this._super();return e["oj-dvtbase oj-timeline"]={path:"styleDefaults/animationDuration",property:"ANIM_DUR"},e["oj-timeline"]={path:"styleDefaults/borderColor",property:"border-color"},e["oj-timeline-item"]=[{path:"styleDefaults/item/borderColor",property:"border-color"},{path:"styleDefaults/item/backgroundColor",property:"background-color"}],e["oj-timeline-item oj-hover"]=[{path:"styleDefaults/item/hoverBorderColor",property:"border-color"},{path:"styleDefaults/item/hoverBackgroundColor",property:"background-color"}],e["oj-timeline-item oj-selected"]=[{path:"styleDefaults/item/selectedBorderColor",property:"border-color"},{path:"styleDefaults/item/selectedBackgroundColor",property:"background-color"}],e["oj-timeline-item-description"]={path:"styleDefaults/item/descriptionStyle",property:"TEXT"},e["oj-timeline-item-title"]={path:"styleDefaults/item/titleStyle",property:"TEXT"},e["oj-timeline-major-axis-label"]={path:"styleDefaults/majorAxis/labelStyle",property:"TEXT"},e["oj-timeline-major-axis-separator"]={path:"styleDefaults/majorAxis/separatorColor",property:"color"},e["oj-timeline-minor-axis"]=[{path:"styleDefaults/minorAxis/backgroundColor",property:"background-color"},{path:"styleDefaults/minorAxis/borderColor",property:"border-color"}],e["oj-timeline-minor-axis-label"]={path:"styleDefaults/minorAxis/labelStyle",property:"TEXT"},e["oj-timeline-minor-axis-separator"]={path:"styleDefaults/minorAxis/separatorColor",property:"color"},e["oj-timeline-overview"]={path:"styleDefaults/overview/backgroundColor",property:"background-color"},e["oj-timeline-overview-label"]={path:"styleDefaults/overview/labelStyle",property:"TEXT"},e["oj-timeline-overview-window"]=[{path:"styleDefaults/overview/window/backgroundColor",property:"background-color"},{path:"styleDefaults/overview/window/borderColor",property:"border-color"}],e["oj-timeline-reference-object"]={path:"styleDefaults/referenceObject/color",property:"color"},e["oj-timeline-series"]={path:"styleDefaults/series/backgroundColor",property:"background-color"},e["oj-timeline-series-empty-text"]={path:"styleDefaults/series/emptyTextStyle",property:"TEXT"},e["oj-timeline-series-label"]={path:"styleDefaults/series/labelStyle",property:"TEXT"},e["oj-timeline-tooltip-label"]={path:"styleDefaults/tooltipLabelStyle",property:"TEXT"},e},_LoadResources:function(){this._super();var e=this.options._resources,t=e.converter,o=new s.IntlDateTimeConverter({month:"short"}),r=new s.IntlDateTimeConverter({year:"2-digit"}),i={seconds:t.seconds,minutes:t.minutes,hours:t.hours,days:t.days,weeks:t.weeks,months:o,quarters:o,years:r};e.converterVert=i,e.zoomIn="oj-fwk-icon oj-fwk-icon-plus",e.zoomOut="oj-fwk-icon oj-fwk-icon-minus",e.overviewHandleHor="oj-fwk-icon oj-fwk-icon-drag-horizontal",e.overviewHandleVert="oj-fwk-icon oj-fwk-icon-drag-vertical"},_GetComponentDeferredDataPaths:function(){return{root:["series","data"]}},_GetSimpleDataProviderConfigs:function(){return{data:{templateName:"itemTemplate",templateElementName:"oj-timeline-item",resultPath:"series",getAliasedPropertyNames:function(e){return"oj-timeline-item"===e?{label:"title"}:{}},expandedKeySet:new e.AllKeySetImpl}}},_GetDataProviderSeriesConfig:function(){return{dataProperty:"data",defaultSingleSeries:!0,idAttribute:"seriesId",itemsKey:"items",templateName:"seriesTemplate",templateElementName:"oj-timeline-series"}},getContextByNode:function(e){var t=this.getSubIdByNode(e);return t&&"oj-timeline-tooltip"!==t.subId?t:null}}),a.extension._WIDGET_NAME="ojTimeline",e.CustomElementBridge.register("oj-timeline",{metadata:a}),p.extension._CONSTRUCTOR=function(){},e.CustomElementBridge.register("oj-timeline-item",{metadata:p}),y.extension._CONSTRUCTOR=function(){},e.CustomElementBridge.register("oj-timeline-series",{metadata:y})});