define(["knockout","jraf/utils/ValidationUtils","ojs/ojchart"],(function(e,r){"use strict";return function(t){if(!(r.isObjectStrict(t)&&r.isArray(e.unwrap(t.series))&&r.isArray(e.unwrap(t.groups))&&r.isArray(e.unwrap(t.valueFormats))&&r.isNonemptyString(e.unwrap(t.centerLabel))))throw new TypeError("SimpleDonutChart: Invalid params.");this.innerRadius=.8,this.centerLabel=t.centerLabel,this.labelStyle=e.observable("font-weight: bold; font-size: 15px; color: #000"),this.pieSeriesValue=t.series,this.pieGroupsValue=e.toJS(t.groups),this.valueFormats=e.toJS(t.valueFormats)}}));