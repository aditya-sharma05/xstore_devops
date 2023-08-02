define(["ojs/ojcore","jraf/utils/ValidationUtils","ojs/ojcollectiondatagriddatasource"],(function(t,i){"use strict";function c(t){c.superclass.constructor.apply(this,arguments),this.collection=this.collection||t,this.ic()}return t.Object.createSubclass(c,t.CollectionDataGridDataSource,"MultipleSortDataSource"),c.prototype.ic=function(){var t=Object.keys(this);for(var c in t){var o=t[c],s=this[o];i.isObjectStrict(s)&&s.hasOwnProperty("axis")&&s.hasOwnProperty("direction")&&s.hasOwnProperty("key")&&(this.tc=o)}},c.prototype.sort=function(t,i,o){o=o||{},null!==t?"column"===t.axis?(this.collection.sortCriteria=[{column:t.key,direction:"ascending"===t.direction?"asc":"desc"}],this.collection.comparator=t.key,this.collection.sortDirection="ascending"===t.direction?1:-1,this.collection.sort(),this.sc(t.key),i&&i.success&&i.success.call(o.success)):i&&i.error&&i.error.call(o.error,"Invalid axis value"):c.superclass.sort.call(this,t,i,o)},c.prototype.sc=function(t){var c,o;c=this.collection.comparator,o=-1===this.collection.sortDirection?"descending":"ascending";var s={};null===t&&i.isFunction(c)||(s.axis="column",s.direction=o,s.key=null===t?c:null),this.tc||this.ic(),this.tc&&(this[this.tc]=s)},c}));