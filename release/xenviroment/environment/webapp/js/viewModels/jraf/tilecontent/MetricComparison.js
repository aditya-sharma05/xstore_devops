define(["ojs/ojcore","knockout","jraf/utils/ValidationUtils","jraf/composites/oj-rgbu-jraf-metric-comparison/loader"],(function(r,t,i){"use strict";return function(r){if(!i.isObjectStrict(r)||!i.isArray(t.unwrap(r.metricData)))throw new TypeError("MetricComparison: Invalid input parameters.");this.metricData=r.metricData}}));