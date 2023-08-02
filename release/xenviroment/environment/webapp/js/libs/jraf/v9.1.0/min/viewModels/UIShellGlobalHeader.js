define(["ojs/ojcore","knockout","jquery","jraf/jrafcore","jraf/utils/AppContextUtils","jraf/utils/ValidationUtils","jraf/models/UIShellManager","jraf/models/Content","jraf/models/HeaderState","jraf/models/HeaderMenus","ojs/ojknockouttemplateutils","ojs/ojarraydataprovider","jraf/composites/oj-rgbu-jraf-message-dialog/loader","ojs/ojknockout","ojs/ojselectsingle","ojs/ojselectcombobox","ojs/ojbutton","ojs/ojmenu","ojs/ojrouter"],(function(e,t,a,l,r,i,n,o,s,h,c,u){"use strict";var b=e.Translations.getTranslatedString;function p(e){if(!i.isObjectStrict(e)||!i.isBoolean(e.renderMenuPin())||!i.isBoolean(e.supportsMenuPin)||!i.isBoolean(e.renderGlobalMenuArea)||!i.isBoolean(e.renderApplicationName)||!i.isBoolean(e.renderProcessingIndicator)||!(e.headerState instanceof s)||e.supportsMenuPin&&!t.isPureComputed(e.pinned)||e.renderGlobalMenuArea&&!(e.headerMenus instanceof h))throw new TypeError("UIShellGlobalHeader: Invalid param(s).");this.currentSelectionLabel=b("jraf.common.currentSelectionLabel"),this.applicationName=l.App.getApplicationName(),this.logoLabel=b("jraf.global.logoLabel"),this.headerState=e.headerState,this.renderApplicationName=e.renderApplicationName,this.renderProcessingIndicator=e.renderProcessingIndicator,this.applicationContext=r.getApplicationContext(),this.jb(e),this.bb(e),this.db(e)}return p.MINIMUM_AUTOSUGGEST_LENGTH=1,p.MAXIMUM_AUTOSUGGEST_RESULT_COUNT=3,p.DEFAULT_FILTER_SECTION={value:-1,label:b("jraf.global.searchDefaultFilterLabel"),jrafTestId:"global-header-search-section-default"},p.ALL_RESULTS_OPTION={value:"-1",label:b("jraf.global.searchAllResultsLabel")},p.prototype.jb=function(e){if(this.renderMenuPin=e.renderMenuPin,this.supportsMenuPin=e.supportsMenuPin,this.supportsMenuPin){var a=this;this.menuPinHeaderLabel=b("jraf.global.menu"),this.menuPinTooltipLabel=b("jraf.global.pin"),this.menuPinActiveTooltipLabel=b("jraf.global.unpin"),this.menuPinned=e.pinned,this.menuPinTooltip=t.computed((function(){return this.menuPinned()?this.menuPinActiveTooltipLabel:this.menuPinTooltipLabel}),this),this.toggleMenuPin=function(){a.gb()}}},p.prototype.bb=function(e){var a=this;this.renderGlobalMenuArea=e.renderGlobalMenuArea,this.renderGlobalMenuArea&&(this.Dl=e.headerMenus,this.userMenuId=l.UIShell.generateUniqueId(),this.helpMenuId=l.UIShell.generateUniqueId(),this.helpMenuLabel=b("jraf.global.help"),this.mb=this.Dl.getUserData(),this.handleMenuSelect=function(e,t){a.Dl.handleMenuItemSelection(e.target.id)},this.userMenuItems=this.Dl.getUserMenu(),this.helpMenuItems=this.Dl.getHelpMenu(),this.username=this.mb.username,this.userAvatar=t.pureComputed((function(){var e=this.mb.avatar();return i.isNonemptyString(e)?".jraf-global-header-user-button-icon { background-image: url('"+e+"'); }":null}),this))},p.prototype.db=function(e){if(this.globalSearchSectionFilterCallback=e.globalSearchSectionFilterCallback,this.globalSearchCallback=e.globalSearchCallback,this.hasGlobalSearchCallback=i.isFunction(this.globalSearchCallback),this.globalSearchContextCallback=e.globalSearchContextCallback,this.globalSearchAllResultsCallback=e.globalSearchAllResultsCallback,this.hasGlobalSearchCallback&&i.isFunction(this.globalSearchSectionFilterCallback)&&i.isFunction(this.globalSearchContextCallback)&&i.isFunction(this.globalSearchAllResultsCallback)){var a=this;this.searchActive=t.observable(!1),this.sectionFilterInputId=l.UIShell.generateUniqueId(),this.globalSearchInputId=l.UIShell.generateUniqueId(),this.globalSearchOptionTemplateId=l.UIShell.generateUniqueId(),this.minimumAutosuggestLength=p.MINIMUM_AUTOSUGGEST_LENGTH,this.pickerAttributes={class:"jraf-global-header-search-result-list"},this.searchMenuFilterListSelection=t.observableArray([p.DEFAULT_FILTER_SECTION.value]),this.searchFilterComponentLabel=b("jraf.global.searchFilterComponentLabel"),this.sectionFilters=t.observableArray([{value:p.DEFAULT_FILTER_SECTION.value,label:p.DEFAULT_FILTER_SECTION.label,jrafTestId:p.DEFAULT_FILTER_SECTION.jrafTestId}]),this.Qj(),this.sectionFiltersDataProvider=new u(this.sectionFilters,{keyAttributes:"value"}),this.pb=[],this.globalSearchString=t.observableArray([]),this.globalSearchPlaceholderText=b("jraf.global.searchPlaceholderText"),this.noResultsLabel=b("jraf.messages.noResults"),this.deactivateGlobalSearchAriaLabel=b("jraf.global.deactivateGlobalSearchAriaLabel"),this.activateGlobalSearchAriaLabel=b("jraf.global.activateGlobalSearchAriaLabel"),this.globalSearchAriaLabel=b("jraf.global.globalSearchAriaLabel"),this.getGlobalSearchOptionTemplate=function(){return c.getRenderer(a.globalSearchOptionTemplateId)},this.getGlobalSearchAutosuggestOptions=function(e){return i.isString(e.term)?(a.lastSearchTerm=e.term,a.Sb(e.term)):(a.lastSearchTerm="",Promise.resolve([]))},this.handleGlobalSearchSubmission=function(e,t){a.Ib(e,t)},this.toggleGlobalSearch=function(){a.Lb()},this.globalSearchState=t.pureComputed((function(){var e={};return this.searchActive()?(e.ariaLabel=this.deactivateGlobalSearchAriaLabel,e.filterDisabled=!1):(e.ariaLabel=this.activateGlobalSearchAriaLabel,e.filterDisabled=!0),e}),this),this.filterDisabled=t.pureComputed((function(){return this.globalSearchState().filterDisabled}),this),this.currentGlobalSearchAriaLabel=t.pureComputed((function(){return this.globalSearchState().ariaLabel}),this)}},p.prototype.gb=function(){this.menuPinned()?n.closeMenu():n.pinMenu()},p.prototype.Qj=function(){var t=this;return this.Tb().then((function(e){t.sectionFilters(e)}),(function(t){e.Logger.warn("UIShellGlobalHeader._initializeSectionFilterList: Error loading sections: ",t)}))},p.prototype.Tb=function(){var t=this;return this.globalSearchSectionFilterCallback().then((function(e){return t.Wj(e)}),(function(t){e.Logger.warn("UIShellGlobalHeader._getSectionFilterOptions: Error loading sections: ",t)}))},p.prototype.Wj=function(e){var t=[];t.push({value:p.DEFAULT_FILTER_SECTION.value,label:p.DEFAULT_FILTER_SECTION.label,jrafTestId:p.DEFAULT_FILTER_SECTION.jrafTestId});for(var a=0;a<e.length;a++){var l=e[a];t.push({value:l.value,label:""+l.label,jrafTestId:"global-header-search-section-"+a})}return t},p.prototype.Sb=function(t){var a=this;if(t.length>=this.minimumAutosuggestLength){var l=this.kb(t);return this.globalSearchCallback(l).then((function(e){return a.pb=e,a.Ub(a.pb)}),(function(t){e.Logger.warn("UIShellGlobalHeader._getGlobalSearchAutosuggestOptions: Error loading search: ",t)}))}},p.prototype.kb=function(e){var t=this.searchMenuFilterListSelection()[0];return t===p.DEFAULT_FILTER_SECTION.value?{searchText:e}:{searchText:e,sectionId:t}},p.prototype.Ib=function(e,t){if("ojValueUpdated"===e.type){var a=""+e.detail.value;if(i.isNonemptyString(a)){if(a===p.ALL_RESULTS_OPTION.value)return this.Ab(),!0;for(var l=this.pb,r=0;r<l.length;r++){var n=l[r];if(""+n.value===a)return this.Gb(n.value),this.globalSearchString.pop(),!0}return this.Ab(),!0}if(!i.isNonemptyString(a))return this.Ab(),!0}return!1},p.prototype.Ab=function(){var e=this.kb(this.lastSearchTerm);this.Hb(e),this.globalSearchString.pop()},p.prototype.Ub=function(e){for(var t=[],a={},l=e.length>p.MAXIMUM_AUTOSUGGEST_RESULT_COUNT?p.MAXIMUM_AUTOSUGGEST_RESULT_COUNT:e.length,r=0;r<l;r++){var i=e[r];t.push({value:""+i.value,label:i.label,metadata:i.metadata||"",jrafTestId:"global-header-search-result-"+r}),a[i.label]=void 0===a[i.label]}if(0===t.length)t.push({label:this.noResultsLabel});else{for(var n=0;n<t.length;n++){var o=t[n];a[o.label]||(o.label=o.label+" "+o.value)}e.length>p.MAXIMUM_AUTOSUGGEST_RESULT_COUNT&&t.push({value:p.ALL_RESULTS_OPTION.value,label:p.ALL_RESULTS_OPTION.label,last:!0})}return t},p.prototype.Gb=function(e){return this.globalSearchContextCallback(e).then((function(e){var t=new o(e);t&&n.openContent(t)}))},p.prototype.Hb=function(e){return this.globalSearchAllResultsCallback(e).then((function(e){"object"==typeof e.targetProperties&&null!==e.targetProperties&&(e.targetProperties.reloadTab=!0);var t=new o(e);t&&n.openContent(t)}))},p.prototype.Lb=function(){this.searchActive()?(a(".jraf-global-header-search-container").removeClass("active"),a(".jraf-global-header-filter-container").removeClass("active"),a(".jraf-global-header-close-search-icon-container").removeClass("active")):(a(".jraf-global-header-search-container").addClass("active"),a(".jraf-global-header-filter-container").addClass("active"),a(".jraf-global-header-close-search-icon-container").addClass("active")),this.searchActive(!this.searchActive())},p}));