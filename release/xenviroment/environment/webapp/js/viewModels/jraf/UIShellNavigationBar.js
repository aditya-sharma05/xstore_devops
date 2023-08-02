define(["ojs/ojcore","knockout","jquery","jraf/jrafcore","jraf/models/UIShellManager","jraf/models/NavigationConfig","jraf/models/favorites/FavoritesConfig","jraf/models/favorites/PinnedFavoritesState","jraf/models/favorites/FavoritesContent","jraf/utils/ValidationUtils","jraf/models/Content","ojs/ojtoolbar","ojs/ojbutton","ojs/ojconveyorbelt","ojs/ojmenu","ojs/ojoption","jraf/utils/CustomBindings"],(function(e,t,n,i,o,r,a,s,d,u,l){"use strict";var I=e.Translations.getTranslatedString;function v(e){var n=this;if(!(u.isObjectStrict(e)&&u.isArray(e.menuItems)&&u.isNonemptyString(e.menuContainerId)&&t.isObservable(e.selectedMenuItemId)&&u.isBoolean(e.pinnedFavoritesEnabled)))throw new TypeError("UIShellNavigationBar: Missing required properties.");this.menuItemButtonSetLabel=I("jraf.navbar.menuItemButtonSetLabel"),this.pinnedFavoritesMenuAriaLabel=I("jraf.sidebar.favorites.pinnedFavoritesMenuAriaLabel"),this.pinnedFavoriteMenuUnpin=I("jraf.sidebar.favorites.pinnedFavoriteMenuUnpin"),this.pinnedFavoriteMenuUnpinAndRemove=I("jraf.sidebar.favorites.pinnedFavoriteMenuUnpinAndRemove"),this.pinnedFavoriteMenuEditFavorites=I("jraf.sidebar.favorites.pinnedFavoriteMenuEditFavorites"),this.editFavoritesPageTitle=I("jraf.sidebar.favorites.editFavoritesPageTitle"),this.menuContainerId=e.menuContainerId,this.selectedMenuItemId=e.selectedMenuItemId,this.lastSelectedMenuItemId=this.selectedMenuItemId(),this.buttonSetId=i.UIShell.generateUniqueId(),this.buttonSetSelector="#"+this.buttonSetId,this.menuItemButtonTemplateId=i.UIShell.generateUniqueId(),this.settingsButtonSetId=i.UIShell.generateUniqueId(),this.pinnedFavoritesButtonSetId=i.UIShell.generateUniqueId(),this.pinnedFavoriteButtonTemplateId=i.UIShell.generateUniqueId(),this.pinnedFavoritesContextMenuId=i.UIShell.generateUniqueId(),this.mainMenuSelectedItemId=t.observable(),this.settingsMenuSelectedItemId=t.observable(),this.pinnedFavoritesSelectedItemId=t.observable(),this.selectedMenuItemId.subscribe((function(e){this.lastSelectedMenuItemId!==e&&null===e&&(this.mainMenuSelectedItemId(e),this.settingsMenuSelectedItemId(e),this.lastSelectedMenuItemId=e)}),this),this.showSettingsMenu=t.observable(!1),this.pinnedFavoritesEnabled=e.pinnedFavoritesEnabled,this.hasFavoritesMenuItem=t.observable(!1),this.showPinnedFavorites=t.pureComputed((function(){return n.hasFavoritesMenuItem()&&n.pinnedFavoritesEnabled})),this.menuItems=e.menuItems,this.handleButtonPress=function(e,t){n._handleButtonPress(e.target.id,e.target.value)},this.handlePinnedFavoriteButtonPress=function(e,t){n._handlePinnedFavoriteButtonPress(e.target.value)},this.pinnedFavoriteContextBeforeOpen=function(e,t){return n._handleBeforeOpenPinnedFavoriteContextMenu(e,t)},this.pinnedFavoriteContextSelect=function(e,t){return n._handleSelectPinnedFavoriteContextMenu(e,t)}}return v.prototype.connected=function(){e.Logger.info("UIShellNavigationBar.connected: Connecting UIShellNavigationBar module."),this.uiMenuItems||this._initMenuItems()},v.prototype._initMenuItems=function(){var e=0;this.uiMenuItems=this.menuItems.map((function(t){return e++,this._parseMenuItem(t,e)}),this),this.menuItemModelIdToUiIdMap={},this.uiMenuItems.forEach((function(e){this.menuItemModelIdToUiIdMap[e.id]=e.guid,r.FAVORITES_ID===e.id&&this.hasFavoritesMenuItem(!0)}),this),this._initSettingsMenuItems(),this._initPinnedFavoritesMenuItems()},v.prototype._initSettingsMenuItems=function(){this.settingsMenuItems=this.uiMenuItems.filter((function(e){return r.SETTINGS_ID===e.id})),this.settingsMenuItems.length>0&&(this.showSettingsMenu(!0),this.uiMenuItems=this.uiMenuItems.filter((function(e){return r.SETTINGS_ID!==e.id})))},v.prototype._initPinnedFavoritesMenuItems=function(){var t=this;this.showPinnedFavorites()&&(this.pinnedFavorites=s.getInstance().getPinnedFavorites(),this.pinnedFavoritesSubscription=this.pinnedFavorites.subscribe((function(){var i=document.getElementById(t.pinnedFavoritesButtonSetId);e.Context.getContext(i).getBusyContext().whenReady().then((function(){n("#"+t.pinnedFavoritesButtonSetId).ojButtonset("refresh")}))})))},v.prototype._parseMenuItem=function(e,t){return{guid:i.UIShell.generateUniqueId(),id:e.getId(),iconLabel:e.getIconLabel(),icon:this._getIconClassComputed(e),badgingEnabled:e.isBadgingEnabled(),badgeValue:e.getBadgeValue(),jrafTestId:"navigation-bar-top-menu-"+t}},v.prototype._getIconClassComputed=function(e){return t.pureComputed((function(){var t=e.getId()===this.selectedMenuItemId();return this._getMenuItemIconClassString(e,t)}),this)},v.prototype._getMenuItemIconClassString=function(e,t){return"jraf-navbar-icon "+e.getIcon(t)},v.prototype.getPinnedFavoriteGuid=function(e){return e.navBarGuid||(e.navBarGuid=i.UIShell.generateUniqueId()),e.navBarGuid},v.prototype.getPinnedFavoriteIcon=function(e){var t=s.favoriteIcons[e.favorite.favoriteType];return"jraf-navbar-icon "+(t=t||s.favoriteIcons.unknown)},v.prototype.getPinnedFavoriteIconLabel=function(e){return a.getInstance().getFavoriteHandler(e.favoriteHandlerKey).getLocalizedTitle(e.favorite.entryId)},v.prototype.getPinnedFavoriteIconLabelForJrafTestId=function(e){return"navigation-bar-top-menu-favorite-"+e.favorite.localPinSequence()},v.prototype.disconnected=function(){e.Logger.info("UIShellNavigationBar.disconnected: Disconnecting UIShellNavigationBar module."),this.uiMenuItems=null,this.pinnedFavoritesSubscription&&(this.pinnedFavoritesSubscription.dispose(),this.pinnedFavoritesSubscription=null)},v.prototype._getMenuItem=function(e){var t=this.menuItems.filter((function(t){return t.getId()===e}));if(1!==t.length)throw new Error("UIShellNavigationBar._getMenuItem: unable to find a unique menu item identified by "+e);return t[0]},v.prototype._handleButtonPress=function(t,n){if(u.isNonemptyString(n)){t===this.settingsButtonSetId?(this.mainMenuSelectedItemId(null),this._updateSelectedMenuItemId(this.settingsMenuSelectedItemId())):(this.settingsMenuSelectedItemId(null),this._updateSelectedMenuItemId(this.mainMenuSelectedItemId()));var i=this._getMenuItem(n);i.hasContent()?this._openContent(i):this._openMenu(i)}else e.Logger.info("UIShellNavigationBar._handleButtonPress: Ignoring invalid menuItemId %s.",n)},v.prototype._updateSelectedMenuItemId=function(e){this.lastSelectedMenuItemId=e,this.selectedMenuItemId(e)},v.prototype._handlePinnedFavoriteButtonPress=function(t){if(e.Logger.info("UIShellNavigationBar._handlePinnedFavoritesButtonPress: Entering with pinnedFavoriteId: "+t),t){var n=s.getInstance().lookupPinnedFavoriteById(t),i=n.favoriteHandlerKey;a.getInstance().getFavoriteHandler(i).openContent(n.favorite.entryId),this.pinnedFavoritesSelectedItemId(null)}},v.prototype._handleBeforeOpenPinnedFavoriteContextMenu=function(e,t){var i=e.detail.originalEvent.srcElement,o=n(i).closest("oj-option").get(0);return o?(this.pinnedFavoriteContextTarget=o.value,!0):(e.preventDefault(),!1)},v.prototype._handleSelectPinnedFavoriteContextMenu=function(e,t){var n=e.target.value;"Unpin"===n?this._unpinFavoriteTarget():"UnpinAndRemove"===n?this._unpinAndRemoveFavoriteTarget():"EditFavorites"===n&&this._handleEditFavorites()},v.prototype._unpinFavoriteTarget=function(){var e=this._getPinnedFavoriteContextTarget();e&&this._getFavoritesContent(e.favoriteHandlerKey).unpinFavorite(e.favorite.entryId)},v.prototype._getPinnedFavoriteContextTarget=function(){var e=this;return s.getInstance().getPinnedFavorites()().filter((function(t){return t.pinnedFavoriteId===e.pinnedFavoriteContextTarget}))[0]},v.prototype._getFavoritesContent=function(e){var t=a.getInstance().getFavoriteHandler(e);return d.getInstance(t.getFavoritesService(),e)},v.prototype._unpinAndRemoveFavoriteTarget=function(){var e=this._getPinnedFavoriteContextTarget();e&&this._getFavoritesContent(e.favoriteHandlerKey).removeFavorite(e.favorite.contentId,e.favorite.objectId)},v.prototype._handleEditFavorites=function(){o.openContent(this._getEditFavoritesPageContent())},v.prototype._getEditFavoritesPageContent=function(){var e=this._getPinnedFavoriteContextTarget();if(e)return l.createModuleGlobalModalPageContent(this.editFavoritesPageTitle,{name:"jraf/favorites/EditFavoritesPage",params:{hidePinnedFavorites:!this.pinnedFavoritesEnabled,favoriteHandlerKey:e.favoriteHandlerKey}})},v.prototype._openContent=function(e){o.closePopupMenu(),o.openContent(e.getContent())},v.prototype._openMenu=function(e){o.openPopupMenu({launcherId:this._getLauncherId(e),moduleBinding:e.getHorizontalMenuModuleBinding()})},v.prototype._getLauncherId=function(e){return this.menuItemModelIdToUiIdMap[e.getId()]},v}));