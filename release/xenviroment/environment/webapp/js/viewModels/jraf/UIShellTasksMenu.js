define(["ojs/ojcore","knockout","jquery","jraf/jrafcore","jraf/utils/ValidationUtils","jraf/models/Content","jraf/models/UIShellManager","jraf/models/tasks/TasksListModel","ojs/ojknockouttemplateutils","ojs/ojarraydataprovider","ojs/ojknockout","ojs/ojbutton","ojs/ojlistview","ojs/ojselectcombobox","ojs/ojmodule"],(function(e,t,i,s,a,n,r,o,l,h){"use strict";var u=e.Translations.getTranslatedString;function d(i){if(e.Logger.info("UIShellTasksMenu: Entering constructor."),!(a.isObjectStrict(i)&&a.isNonemptyString(i.header)&&a.isNonemptyString(i.navListLabel)&&a.isNonemptyString(i.searchPlaceholderText)&&a.isNonemptyString(i.autosuggestAdditionalResultsText)&&a.isFunction(i.getTasks)))throw new TypeError("UIShellTasksMenu: Missing required parameters.");var n=this;this.expandCollapseButtonId=s.UIShell.generateUniqueId(),this.navListId=s.UIShell.generateUniqueId(),this.searchInputId=s.UIShell.generateUniqueId(),this.autosuggestOptionTemplateId=s.UIShell.generateUniqueId(),this._initializeTasksModel(i),this._initializeHierarchyExpansion(),this._initializeAutosuggestData(i),this._initializeCloseHandlers(),this.navigateUpHierarchy=function(){n._handleNavigateUpHierarchy()},this.hierarchyNodeSelection=t.observableArray([]),this.handleHierarchyOptionChange=function(e){0!==e.detail.value.length&&(n.hierarchyNodeSelection([]),n._handleHierarchyNodeSelection(e.detail.value[0]))},this.tasksListBodyModule={name:"jraf/tasks/TasksMenuBody",params:{navListId:this.navListId,navListLabel:i.navListLabel,openContentCallback:function(e){n._openContent(e)},tasksModel:this._tasksModel}},this.getAutosuggestOptionTemplate=function(){return l.getRenderer(n.autosuggestOptionTemplateId)}}return d.prototype._initializeCloseHandlers=function(){var e=this;this.handleDetached=function(){e.searchString.pop()},r.getMenuDrawerState().subscribe((function(t){t||e.searchString.pop()}))},d.prototype._initializeTasksModel=function(e){this._tasksModel=new o({getTasks:e.getTasks,taskId:e.taskId,favoritesEnabled:e.favoritesEnabled,favoritesType:e.favoritesType}),this.hierarchyDrillPath=this._tasksModel.getHierarchyDrillPath(),this.drilledNode=this._tasksModel.getDrilledNode(),this.rootNodeLabel=u(e.header),this.hierarchyDrillPathDataProvider=new h(this.hierarchyDrillPath,{keyAttributes:"id"}),this.drilledNodeLabel=t.pureComputed((function(){return this.drilledNode().label}),this),this.isHierarchyRoot=t.pureComputed((function(){return this.hierarchyDrillPath().length<1}),this),this.isHierarchyRoot.subscribe((function(e){e&&this._collapseHierarchy()}),this)},d.prototype._initializeHierarchyExpansion=function(){this.hierarchyExpanded=t.observableArray([]),this.isHierarchyExpanded=t.pureComputed((function(){return this.hierarchyExpanded().length>0}),this),this.hierarchyExpansionLabel=t.computed((function(){return this.isHierarchyExpanded()?u("jraf.sidebar.collapseMenuTree"):u("jraf.sidebar.expandMenuTree")}),this),this.hierarchyExpansionIcon=t.computed((function(){var e="jraf-background-icon";return this.isHierarchyExpanded()?e+=" jraf-hierarchy-selection-collapse-icon":e+=" jraf-hierarchy-selection-expand-icon",e}),this)},d.prototype._initializeAutosuggestData=function(e){var i=this;this.searchPlaceholderText=u(e.searchPlaceholderText),this.noResultsText=u("jraf.messages.noResults"),this.autosuggestAdditionalResultsText=u(e.autosuggestAdditionalResultsText),this.searchString=t.observableArray([]),this.autosuggestOptionsKeys={children:"additionalResults"},this.autosuggestLabelsMap={},this._tasksModel.getMenuDataLoaded().subscribe((function(e){if(e){var t=i._tasksModel.getRootContent();t instanceof n&&(i.autosuggestLabelsMap={},i._buildAutosuggestLabelMap(t,!0,"",i.autosuggestLabelsMap))}})),this.getAutosuggestOptions=function(e){return i._getAutosuggestOptions(e)},this.handleSearchSubmission=function(e){return i._handleSearchSubmission(e)},this.searchInputPickerAttributes={class:"jraf-sidebar-search"}},d.prototype._buildAutosuggestLabelMap=function(e,t,i,s){if(e.isLaunchable()){var n=e.getTitle(),r=a.isNonemptyString(i)?i:"";s[e.getId()]={label:n,path:r}}else if(e.isFolder()){t||(a.isNonemptyString(i)&&(i+=" / "),i+=e.getTitle());for(var o=e.getChildren(),l=0;l<o.length;l++)this._buildAutosuggestLabelMap(o[l],!1,i,s)}},d.prototype._getAutosuggestOptions=function(e){var t=[];if(!a.isString(e.term))return Promise.resolve([]);var i=e.term,s=this.isHierarchyRoot(),n=s?this._tasksModel.getRootContent():this._tasksModel.getUIContent(this.drilledNode().id),r=[];if(this._buildOrderedContentIdArray(n,null,r),r.length>0){var o=this._getRegularAutosuggestOptions(r,i);t=t.concat(o)}if(!s){var l=[];if(this._buildOrderedContentIdArray(this._tasksModel.getRootContent(),n.getId(),l),l.length>0){var h=this._getRegularAutosuggestOptions(l,i);h.length>0&&t.push({label:this.autosuggestAdditionalResultsText,additionalResults:h})}}return 0===t.length&&t.push({label:this.noResultsText}),Promise.resolve(t)},d.prototype._getRegularAutosuggestOptions=function(e,t){for(var i=[],s=0;s<e.length;s++){var a=e[s],n=this.autosuggestLabelsMap[a].label,r=this.autosuggestLabelsMap[a].path,o=t.toLowerCase();(n.toLowerCase().indexOf(o)>=0||r.toLowerCase().indexOf(o)>=0)&&i.push({value:a,label:n,path:r})}return i},d.prototype._buildOrderedContentIdArray=function(e,t,i){if(e.isFolder()&&e.getId()!==t)for(var s=e.getChildren(),a=0;a<s.length;a++)this._buildOrderedContentIdArray(s[a],t,i);e.isLaunchable()&&i.push(e.getId())},d.prototype._handleSearchSubmission=function(t){var i=t.detail.value;if(!a.isNonemptyString(i))return!1;var s=i;e.Logger.info("UIShellTasksMenu._handleSearchSubmission: Content %s was selected.",s);var r=this._tasksModel.getContent(s);return r instanceof n&&r.isLaunchable()&&(this._openContent(r),this.searchString.pop()),!0},d.prototype._handleNavigateUpHierarchy=function(){if(!this.isHierarchyRoot()){var e=this.hierarchyDrillPath();this._handleHierarchyNodeSelection(e[e.length-1].id)}},d.prototype._handleHierarchyNodeSelection=function(e){for(var t=this.hierarchyDrillPath(),i=t.length-1;i>=0;i--){var s=t[i];if(this._navigateBack(),e===s.id)break}},d.prototype._collapseHierarchy=function(){1===this.hierarchyExpanded().length&&this.hierarchyExpanded.pop()},d.prototype._getNavList=function(){return i("#"+this.navListId)},d.prototype._navigateBack=function(){e.Logger.info("UIShellTasksMenu._navigateBack: Entering."),this._getNavList().find(".oj-navigationlist-previous-link").click()},d.prototype._openContent=function(e){r.openContent(e),r.closeMenu({closeOverlayMenuOnly:!0})},d}));