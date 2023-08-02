define(["ojs/ojcore","knockout","jquery","jraf/jrafcore","jraf/models/Content","jraf/models/TabState","jraf/models/TabStateService","jraf/models/ModalPageManager","jraf/utils/RouterUtils","jraf/utils/ValidationUtils","ojs/ojcorerouter","ojs/ojrouter","ojs/ojnavigationlist","ojs/ojswitcher"],(function(e,t,n,a,o,r,i,s,d,l,b){"use strict";function u(n){var a=this;if(!(l.isObjectStrict(n)&&l.isNonemptyString(n.tabBarComponentId)&&l.isNonemptyString(n.switcherComponentId)&&l.isNonemptyString(n.maxTabsDialogId)&&t.isObservable(n.activeTab)&&t.isObservable(n.tabsData))){var o="TabManager: Invalid configuration passed to TabManager.";throw e.Logger.error(o),new TypeError(o)}this.tabCounter=0,this._initializeTabRouter(),this.activeTab=n.activeTab,this.activeTab.subscribe((function(e){a._handleActiveTabChange(e),a._tabRouter instanceof b?a._tabRouter.go({path:e}):a._tabRouter.go(e)})),this.maxTabsDialogId=n.maxTabsDialogId,this.maxTabCount=l.isNumberStrict(n.maxTabCount)?n.maxTabCount:15,this.tabBarComponentId=n.tabBarComponentId,this.switcherComponentId=n.switcherComponentId,this.tabsData=n.tabsData,this._beforeLoadModuleHandler=n.beforeLoadModuleHandler,this._afterUnloadModuleHandler=n.afterUnloadModuleHandler,this.tabBarComponent=null,this.switcherComponent=null,this.openTabs={}}return u.STATUS_ICON_CLASSES={info:"jraf-tabbar-status jraf-tabbar-info",warning:"jraf-tabbar-status jraf-tabbar-warning",error:"jraf-tabbar-status jraf-tabbar-error",success:"jraf-tabbar-status jraf-tabbar-success"},u.prototype._initializeTabRouter=function(){var t=this,n=a.App.getRootRouter();n?(this._tabRouter=n.createChildRouter([{path:/.*/}]),this._tabRouter.currentState.subscribe((function(e){var n=e.state;if(n){var a=n.path;t._isValidTabReference(a)&&t.setActiveTab(a)}}))):(this._tabRouter=d.createChildRouterForCurrentState().configure((function(t){return t?new e.RouterState(t,{value:t}):void 0})),this._tabRouter.stateId.subscribe((function(e){t._isValidTabReference(e)?t.setActiveTab(e):t._tabRouter.direction?window.history.back():window.history.forward()})))},u.prototype.getOjTabBarComponent=function(){if(!this.tabBarComponent){if(this.tabBarComponent=document.getElementById(this.tabBarComponentId),!this.tabBarComponent){var t="TabManager.getOjTabBarComponent: Could not find tab bar component identified by: "+this.tabBarComponentId;throw e.Logger.error(t),new Error(t)}var n=this;this.tabBarComponent.onOjBeforeDeselect=function(e){return n.handleTabBeforeDeselectEvent(e)},this.tabBarComponent.onOjDeselect=function(e){n.handleTabDeselectEvent(e)},this.tabBarComponent.onOjBeforeSelect=function(e){return n.handleTabBeforeSelectEvent(e)},this.tabBarComponent.onSelectionChanged=function(e){n.handleTabSelectEvent(e)},this.tabBarComponent.onOjBeforeRemove=function(e){return n.handleTabBeforeRemoveEvent(e)},this.tabBarComponent.onOjRemove=function(e){n.handleTabRemoveEvent(e)},this.tabBarComponent.onOjAnimateStart=function(e){n._preventTabAnimations(e)}}return this.tabBarComponent},u.prototype._getOjSwitcherComponent=function(){if(!this.switcherComponent&&(this.switcherComponent=document.getElementById(this.switcherComponentId),!this.switcherComponent)){var t="TabManager._getOjSwitcherComponent: Could not find switcher component identified by: "+this.switcherComponentId;throw e.Logger.error(t),new Error(t)}return this.switcherComponent},u.prototype.setActiveTab=function(e){this.activeTab(e)},u.prototype.getActiveTab=function(){return this.activeTab()},u.prototype._handleActiveTabChange=function(t){if(e.Logger.info("TabManager._handleActiveTabChange: Entering (%s).",t),t){var n=this._getOpenTabData(t);this._scrollTabIntoView(n.uniqueContentId),n.initialDisplay?n.initialDisplay=!1:(this._setTabStatus(n.uniqueContentId,null),n.content.isRefreshOnDisclosure()&&this._refreshTabContent(n))}},u.prototype._scrollTabIntoView=function(t){var a=this.getTabTitleId(t);return e.Context.getContext(this.getOjTabBarComponent()).getBusyContext().whenReady().then((function(){n("#"+a)[0].scrollIntoView(!1)}))},u.prototype.handleTabBeforeDeselectEvent=function(e){if(this._isOjTabBarEvent(e)&&this._isValidTabReference(e.detail.fromKey)){var t=e.detail.fromKey,n=this._getOpenTabData(t),a=this._buildUiObject(e),o=this._invokeModuleEventHandler("uiShellBeforeDeselect",e,a,n.contentId,!0);return!1===o||e.defaultPrevented?(e.detail.fromItem.focus(),this._ensureDefaultPrevented(e),!1):o}},u.prototype._isValidTabReference=function(e){return l.isArray(e)&&(e=e[0]),!!e&&null!==this.findOpenTabReference(e)},u.prototype._ensureDefaultPrevented=function(e){e.defaultPrevented||e.preventDefault()},u.prototype.handleTabDeselectEvent=function(e){if(this._isOjTabBarEvent(e)&&this._isValidTabReference(e.detail.fromKey)){var t=e.detail.fromKey,n=this._getOpenTabData(t),a=this._buildUiObject(e);this._invokeModuleEventHandler("uiShellDeselect",e,a,n.contentId,void 0)}},u.prototype.handleTabBeforeSelectEvent=function(e){if(this._isOjTabBarEvent(e)&&this._isValidTabReference(e.detail.key)){var t=document.querySelector("#"+this.getActiveTab());t&&t.blur();var n=e.detail.key,a=this._getOpenTabData(n),o=this._buildUiObject(e),r=this._invokeModuleEventHandler("uiShellBeforeSelect",e,o,a.contentId,!0);return!1===r||e.defaultPrevented?(t&&t.focus(),this._ensureDefaultPrevented(e),!1):r}},u.prototype.handleTabSelectEvent=function(e){if(this._isOjTabBarEvent(e)&&this._isValidTabReference(e.detail.value)){var t=e.detail.value,a=this._getOpenTabData(t),o=this._buildUiObject(e);this._invokeModuleEventHandler("uiShellSelect",e,o,a.contentId,void 0);var r=n(e.detail.item);this._triggerContentChange(this._getTitleFromTab(r))}},u.prototype._getTitleFromTab=function(e){return e.find("span").text()},u.prototype._triggerContentChange=function(e){n(window.document).trigger("jrafcontentchange",[{title:e}])},u.prototype.handleTabBeforeRemoveEvent=function(t){if(this._isOjTabBarEvent(t)&&this._isValidTabReference(t.detail.key)){var n=t.detail.key,a=this._requireOpenTabReference(n),o=this._getOpenTabData(n),r=this._buildUiObject(t),i=this._getModalPageManager(a.contentKey,a.tabIndex),s=i.handleBeforeCloseAll(t,r);if(!1===s||t.defaultPrevented)return this._ensureDefaultPrevented(t),s;var d=this._invokeModuleEventHandler("uiShellBeforeClose",t,r,o.contentId,!0);return!1===d||t.defaultPrevented?(this._ensureDefaultPrevented(t),!1):(e.Logger.info("TabManager.handleTabBeforeRemoveEvent: Cleaning up tab."),i.dispose(),d)}},u.prototype.handleTabRemoveEvent=function(e){if(this._isOjTabBarEvent(e)&&this._isValidTabReference(e.detail.key)){var n=e.detail.key,a=this._requireOpenTabReference(n),o=a.contentKey,r=this._getOpenTabData(n),i=this._buildUiObject(e);this.openTabs[o].length>1?this.openTabs[o].splice(a.tabIndex,1):delete this.openTabs[o],this._invokeModuleEventHandler("uiShellClose",e,i,r.contentId,void 0),this._handleActiveTabRemoval(n);var s=document.getElementById(r.contentId);t.cleanNode(s),this.tabsData.remove((function(e){return e.tabId===n})),this._persistTabState(),0===this.getOpenTabCount()&&this._triggerContentChange("")}},u.prototype._handleActiveTabRemoval=function(e){var t=this;this.getActiveTab()===e&&this.tabsData().some((function(n,a){if(n.tabId===e)return t._updateActiveTab(a),!0}),this)},u.prototype._updateActiveTab=function(t){var n=this,a=t<this.tabsData().length-1?this.tabsData()[t+1].tabId:t>0?this.tabsData()[t-1].tabId:null;e.Context.getContext(this.getOjTabBarComponent()).getBusyContext().whenReady().then((function(){n.setActiveTab(a),n.getOjTabBarComponent().focus()}))},u.prototype._requireOpenTabReference=function(e){var t=this.findOpenTabReference(e);if(null===t)throw new Error("TabManager._requireOpenTabReference: Could not find tab: "+e);return t},u.prototype._preventTabAnimations=function(e){this._isOjTabBarEvent(e)&&(e.preventDefault(),e.detail.endCallback())},u.prototype._getModalPageManager=function(e,n){var a=this.openTabs[e];if(!Array.isArray(a)||0===a.length||n>=a.length)throw new Error("TabManager._getModalPageManager: cannot find data for "+e+"["+n+"].");var o=a[-1===n?a.length-1:n];return t.isObservable(o.viewModel.moduleBinding)?o.viewModel.moduleBinding().params.jraf.modalPageManager:o.viewModel.moduleOptions().params.jraf.modalPageManager},u.prototype.findOpenTabReference=function(e){for(var t in this.openTabs)for(var n=this.openTabs[t],a=0;a<n.length;a++)if(e===n[a].tabId)return{contentKey:t,tabIndex:a};return null},u.prototype._getOpenTabData=function(e){l.isArray(e)&&(e=e[0]);var t=this.findOpenTabReference(e);if(null===t)throw new Error("TabManager._getOpenTabData: Could not find data for tab: "+e);return this.openTabs[t.contentKey][t.tabIndex]},u.prototype.generateUniqueContentId=function(){return this.tabCounter++,this.tabCounter.toString()},u.prototype.getTabTitleId=function(e){if(!e)throw new Error("Invalid content ID passed to getTabTitleId.");return"jraf-main-content-tab-"+e},u.prototype.getTabContentId=function(e){if(!e)throw new Error("Invalid content ID passed to getTabContentId.");return"jraf-main-content-tab-content-"+e},u.prototype._getModalPageContainerId=function(e){if(!e)throw new TypeError("TabManager._getModalPageContainerId: Invalid content ID.");return"jraf-main-content-tab-content-modal-page-container-"+e},u.prototype.getOpenTabCount=function(){var e=0;for(var t in this.openTabs)e+=this.openTabs[t].length;return e},u.prototype.openModalPageInContent=function(e,t){this.openContent(t);var n=t.isReuseInstance()?0:-1;this._getModalPageManager(t.getContentKey(),n).openContent(e)},u.prototype._setTabProcessing=function(e,t){var n=this.getTabTitleId(e),a=this._getOpenTabData(n);a.displayProcessing(t),t?a.processing(t):window.setTimeout((function(){a.processing(t)}),250)},u.prototype._setTabStatus=function(e,t){var n=this.getTabTitleId(e),a=this._getOpenTabData(n),o=u.STATUS_ICON_CLASSES[t]||null;n===this.activeTab()&&(o=null),a.displayStatus(o),o?a.statusClass(o):window.setTimeout((function(){a.statusClass(o)}),250)},u.prototype.handleSnackbarStatus=function(e,t){var n=e.detail,a=t.data.uniqueContentId;this._setTabStatus(a,n)},u.prototype.openContent=function(t){if(!(t instanceof o)){throw e.Logger.error("TabManager.openContent was not passed a Content instance."),new Error("TabManager.openContent was not passed a Content instance.")}if(!this.shouldShowExistingTab(t))return this.getOpenTabCount()===this.maxTabCount?(e.Logger.warn("TabManager.openContent: Maximum number of tabs are open."),void this.openMaxTabsMessageDialog()):void this.addNewTab(t);this.showTab(t)},u.prototype.openMaxTabsMessageDialog=function(){document.getElementById(this.maxTabsDialogId).open()},u.prototype.shouldShowExistingTab=function(e){return!!e.isReuseInstance()&&this.isContentOpenInTabs(e)},u.prototype.isContentOpenInTabs=function(e){var t=e.getContentKey(),n=this.openTabs[t];return l.isArray(n)&&n.length>0},u.prototype.isTabRemovable=function(e){return this._getOpenTabData(e).content.isRemovable()},u.prototype.getViewModel=function(e,a){if(a.hasModuleOptions()){var o=a.getModuleOptions(),r=n.extend(!0,{},o,{params:this._getJRAFModuleParams(e)});return{moduleOptions:t.observable(r)}}var i=a.getModuleBinding(),s=n.extend(!0,{},i,{params:this._getJRAFModuleParams(e)});return{moduleBinding:t.observable(s)}},u.prototype._getJRAFModuleParams=function(e){var t=this;return{jraf:{uniqueContentId:e,refreshCount:0,modalPageManager:this._createModalPageManager(e),startTabProcessingIndicator:function(){t._setTabProcessing(e,!0)},stopTabProcessingIndicator:function(){t._setTabProcessing(e,!1)}}}},u.prototype._createModalPageManager=function(e){return new s({modalPageContainerId:this._getModalPageContainerId(e),beforeLoadModuleHandler:this._beforeLoadModuleHandler,afterUnloadModuleHandler:this._afterUnloadModuleHandler})},u.prototype.addNewTab=function(e){var t=this.generateUniqueContentId(),n=this.getViewModel(t,e);this.openTab(t,e,n)},u.prototype.openTab=function(e,n,a){var o=this.getTabTitleId(e),r={uniqueContentId:e,tabId:o,contentId:this.getTabContentId(e),modalPageContainerId:this._getModalPageContainerId(e),content:n,viewModel:a,initialDisplay:!0,displayProcessing:t.observable(null),processing:t.observable(!1),displayStatus:t.observable(null),statusClass:t.observable(null),removable:l.getBoolean(n.isRemovable(),!0)};this.addOpenTabState(n.getContentKey(),r),this.tabsData.push(r),this.setActiveTab(o),this.getOjTabBarComponent().refresh(),this._getOjSwitcherComponent().refresh(),this._persistTabState()},u.prototype.addOpenTabState=function(e,t){l.isArray(this.openTabs[e])||(this.openTabs[e]=[]),this.openTabs[e].push(t)},u.prototype.showTab=function(t){var n=t.getContentKey(),a=this.openTabs[n];if(!l.isArray(a)||0===a.length){var o="TabManager.showTab: Could not find open tab reference for contentKey: "+n;throw e.Logger.error(o),new Error(o)}var r=a[0].tabId;e.Logger.info("TabManager.showTab - showing tab: "+r),t.isReloadTab()&&this._refreshTabContent(a[0],t),this.setActiveTab(r)},u.prototype.closeContent=function(t){if(t instanceof o){var n=t.getContentKey(),a=this.openTabs[n];if(!l.isArray(a)){var r="TabManager.closeContent could not find any tabs opened for content: "+n;return void e.Logger.warn(r)}var i,s=[];for(i=0;i<a.length;i++)s.push(a[i].tabId);for(i=0;i<s.length;i++)this.closeTab(s[i])}else{var d=this.getActiveTab();null!==d&&this.closeTab(d)}},u.prototype.closeTab=function(e){var t=document.querySelector("#"+e+" > a.oj-tabbar-remove-icon");t&&t.click()},u.prototype._refreshTabContent=function(a,r){if(e.Logger.info("TabManager._refreshTabContent: Entering."),"object"!=typeof a||null===a||"object"!=typeof a.viewModel||null===a.viewModel||!t.isObservable(a.viewModel.moduleBinding)&&!t.isObservable(a.viewModel.moduleOptions))throw new TypeError("TabManager._refreshTabContent: Invalid openTabData.");if(t.isObservable(a.viewModel.moduleBinding)){var i=a.viewModel.moduleBinding();i.params.jraf.refreshCount++;var s=r instanceof o?s=n.extend(!0,{},i,r.getModuleBinding()):i;a.viewModel.moduleBinding(s)}else if(t.isObservable(a.viewModel.moduleOptions)){var d=a.viewModel.moduleOptions();d.params.jraf.refreshCount++;var l=r instanceof o?n.extend(!0,{},d,r.getModuleOptions()):d;a.viewModel.moduleOptions(l)}},u.prototype._isOjTabBarEvent=function(t){return t.target&&t.target.id&&t.currentTarget&&t.currentTarget.id?t.target.id===t.currentTarget.id||(e.Logger.info("TabManager._isOjTabBarEvent: Ignoring event from different origin %s",t.target.id),!1):(e.Logger.info("TabManager._isOjTabBarEvent: Ignoring event since no event target was provided."),!1)},u.prototype._getTabContentAppsModule=function(e){if(!l.isNonemptyString(e))throw new TypeError("TabManager._getTabContentAppsModule: contentId is required");return n("#"+e).find("oj-rgbu-jraf-apps-module.jraf-global-tabs-tab-content-module").get(0)},u.prototype._invokeModuleEventHandler=function(e,t,n,a,o){return this._getTabContentAppsModule(a).invokeModuleEventHandler(e,t,n,o)},u.prototype._buildUiObject=function(e){var t={};return e.detail.item&&e.detail.key&&(t.tab=n(e.detail.item),t.content=this._getContentForTabId(e.detail.key)),e.detail.fromKey&&e.detail.fromItem&&(t.fromTab=n(e.detail.fromItem),t.fromContent=this._getContentForTabId(e.detail.fromKey)),e.detail.toKey&&e.detail.toItem&&(t.toTab=n(e.detail.toItem),t.toContent=this._getContentForTabId(e.detail.toKey)),t},u.prototype._getContentForTabId=function(e){var t=this._getOpenTabData(e);return n("#"+t.contentId)},u.prototype._persistTabState=function(){var t=this;e.Context.getContext(this.getOjTabBarComponent()).getBusyContext().whenReady().then((function(){i.save(t._getTabState())}))},u.prototype._getTabState=function(){var e=this;return n(this.getOjTabBarComponent()).find("li.jraf-tabs-uishell-tab").map((function(){var t=this.id,n=e._getOpenTabData(t).content;return r.fromContent(n)})).get()},u}));