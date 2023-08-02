define(["ojs/ojcore","knockout","jraf/models/NavigationConfig","jraf/models/UIShellManager"],(function(t,e,n,o){"use strict";function a(t){if(!(t instanceof n))throw new TypeError("LayoutManager: navigationConfig was not a NavigationConfig instance.");this.renderNavigation=t.hasNavigation(),this.layoutConfigurable=t.isLayoutConfigurable(),this.activeLayout=e.observable(this._getDefaultLayout(t)),this.readOnlyActiveLayout=e.pureComputed((function(){return this.activeLayout()}),this),this.renderMenuPin=e.pureComputed((function(){return this._isRenderSidebarMenuArea()}),this),this.renderSidebarMenu=e.pureComputed((function(){return this._isRenderSidebarMenuArea()}),this),this.renderHorizontalBarMenu=e.pureComputed((function(){return this._isRenderLayout(n.HORIZONTAL_LAYOUT)}),this)}return a._instance=null,a.LOCAL_LAYOUT_KEY="jraf.layout",a.prototype.isLayoutConfigurable=function(){return this.layoutConfigurable},a.prototype.getRenderMenuPin=function(){return this.renderMenuPin},a.prototype.getRenderSidebarMenu=function(){return this.renderSidebarMenu},a.prototype.getRenderHorizontalBarMenu=function(){return this.renderHorizontalBarMenu},a.prototype.getActiveLayout=function(){return this.readOnlyActiveLayout},a.prototype.setActiveLayout=function(t){if(!this.isLayoutConfigurable())throw new Error("LayoutManager.setActiveLayout: Layout changes have not been enabled; unable to change layout.");var e=t===n.HORIZONTAL_LAYOUT;if(!e&&t!==n.SIDEBAR_LAYOUT)throw new Error("LayoutManager.setActiveLayout: Invalid layout value.");e?(o.closeMenu(),o.ResetMenu()):o.ResetPopupMenu(),this._saveLayout(t),this.activeLayout(t)},a.prototype.getLayouts=function(){return[{id:n.SIDEBAR_LAYOUT,label:"jraf.global.sidebarLayoutLabel"},{id:n.HORIZONTAL_LAYOUT,label:"jraf.global.topBarLayoutLabel"}]},a.prototype._isRenderSidebarMenuArea=function(){return this._isRenderLayout(n.SIDEBAR_LAYOUT)},a.prototype._isRenderLayout=function(t){var e=this.activeLayout();return this.renderNavigation&&e===t},a.prototype.hasSidebarLayoutSupport=function(){return this._hasLayoutSupport(n.SIDEBAR_LAYOUT)},a.prototype.hasHorizontalBarLayoutSupport=function(){return this._hasLayoutSupport(n.HORIZONTAL_LAYOUT)},a.prototype._hasLayoutSupport=function(t){return this.renderNavigation&&(this.isLayoutConfigurable()||this.activeLayout()===t)},a.dispose=function(){a._instance=null},a.getInstance=function(t){return t instanceof n&&(null!==a._instance&&a.dispose(),a._instance=new a(t)),a._instance},a.prototype._getDefaultLayout=function(t){var e=this._getSavedLayout();return n.isValidLayout(e)&&t.isLayoutConfigurable()?e:t.getDefaultNavigationLayout()},a.prototype._getSavedLayout=function(){return window.localStorage.getItem(a.LOCAL_LAYOUT_KEY)},a.prototype._saveLayout=function(t){window.localStorage.setItem(a.LOCAL_LAYOUT_KEY,t)},a}));